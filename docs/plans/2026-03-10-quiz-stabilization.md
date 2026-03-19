# Quiz Sistemi Stabilizasyon — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Quiz akışındaki tüm power/timer/feedback/matching bug'larını düzelt ve yanlış cevap sonrası SKIP kurtulma mekaniğini ekle.

**Architecture:** Backend'e 2 yeni endpoint (rescue, fail) eklenir. Frontend'de quiz_screen logic'i refactor edilir: power kullanımı ayrı metot, timer pause/resume desteği, wrong answer overlay'e SKIP teklifi eklenir. Answer submission sırasında backend session'ı hemen FAILED yapmaz, client'a kurtulma şansı verir.

**Tech Stack:** Node.js/Express/TypeScript (backend), Flutter/Riverpod (frontend), Supabase PostgreSQL

---

## Task 1: Backend — Yanlış Cevap'ta Session'ı Hemen FAILED Yapma

**Files:**
- Modify: `server/src/services/quiz.service.ts:332-344`

**Step 1: quiz.service.ts'de answerQuestion metodunda yanlış cevap logic'ini değiştir**

Mevcut kod (satır 332-344) yanlış cevapta direkt FAILED yapıyor. Bunu değiştir: session'ı FAILED yapma, IN_PROGRESS olarak bırak. Client'a kurtulma şansı ver.

```typescript
// MEVCUT (SİL):
    if (!isCorrect) {
      // FAILED
      await supabase
        .from("quiz_sessions")
        .update({ status: "FAILED", completed_at: new Date().toISOString() })
        .eq("id", sessionId);

      await this.saveSessionSummary(sessionId);

      // Apply any pending question changes for the target user
      await pendingChangeService.applyPendingChanges(session.target_id);

      return { is_correct: false, session_status: "FAILED" };
    }

// YENİ (EKLE):
    if (!isCorrect) {
      // Session'ı hemen FAILED yapma — client'a SKIP kurtulma şansı ver
      // Session IN_PROGRESS kalır, client rescue veya fail çağrısı yapacak
      return {
        is_correct: false,
        session_status: "IN_PROGRESS",
        can_rescue: true,
      };
    }
```

**Step 2: QuizAnswerResponse model'ine can_rescue ekle — sonraki task'larda yapılacak, şimdilik backend hazır**

**Step 3: Commit**

```bash
git add server/src/services/quiz.service.ts
git commit -m "fix(quiz): don't immediately fail session on wrong answer, allow rescue"
```

---

## Task 2: Backend — Rescue ve Fail Endpoint'leri

**Files:**
- Modify: `server/src/services/quiz.service.ts` (2 yeni metot ekle)
- Modify: `server/src/controllers/quiz.controller.ts` (2 yeni handler)
- Modify: `server/src/routes/quiz.routes.ts` (2 yeni route)
- Modify: `server/src/validators/quiz.validator.ts` (1 yeni schema)

**Step 1: quiz.service.ts'e rescueWithSkip metodu ekle**

Dosyanın sonuna, `getMatchQuizSummary` metodundan önce ekle:

```typescript
  // ─── Rescue with SKIP (after wrong answer) ──────────────────
  async rescueWithSkip(sessionId: string, solverId: string) {
    const session = await this.getActiveSession(sessionId, solverId);

    // Son cevabı bul — yanlış olmalı
    const { data: lastAnswer, error: ansErr } = await supabase
      .from("quiz_answers")
      .select("id, question_id, is_correct")
      .eq("session_id", sessionId)
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (ansErr || !lastAnswer || lastAnswer.is_correct !== false) {
      throw Errors.VALIDATION_ERROR({ rescue: "No wrong answer to rescue" });
    }

    // SKIP power envanter/elmas kontrolü
    const { data: power, error: powerErr } = await supabase
      .from("powers")
      .select("id, name, base_cost, is_active")
      .eq("name", "SKIP")
      .eq("is_active", true)
      .maybeSingle();

    if (powerErr || !power) throw Errors.SERVER_ERROR();

    const usedFromInventory = await exchangeService.tryUseInventory(solverId, "SKIP");

    if (!usedFromInventory) {
      const cost = calculatePowerCost(power.base_cost, session.total_questions);
      const greenReward = calculateGreenReward(cost);

      await diamondService.spendPurple(solverId, cost, "POWER_USED", `SKIP_RESCUE:${sessionId}`);
      await diamondService.earnGreen(session.target_id, greenReward, "POWER_REWARD", `SKIP_RESCUE:${sessionId}`);
    }

    // Yanlış cevabı override et: is_correct → true, power_used → SKIP
    await supabase
      .from("quiz_answers")
      .update({ is_correct: true, power_used: "SKIP" })
      .eq("id", lastAnswer.id);

    // Soru stats güncelle (wrong -1, correct +1)
    const { data: qStats } = await supabase
      .from("questions")
      .select("stats_correct, stats_wrong, stats_skip_used")
      .eq("id", lastAnswer.question_id)
      .single();

    if (qStats) {
      await supabase
        .from("questions")
        .update({
          stats_correct: qStats.stats_correct + 1,
          stats_wrong: Math.max(0, qStats.stats_wrong - 1),
          stats_skip_used: (qStats.stats_skip_used ?? 0) + 1,
        })
        .eq("id", lastAnswer.question_id);
    }

    // Son soru muydu?
    if (session.current_q >= session.total_questions) {
      return await this.completeSession(session);
    }

    // Sonraki soruya geç
    await this.incrementCurrentQ(sessionId, session.current_q);
    return { is_correct: true, next_question: session.current_q + 1, session_status: "IN_PROGRESS" };
  }

  // ─── Fail Session (user declined rescue) ────────────────────
  async failSession(sessionId: string, solverId: string) {
    const session = await this.getActiveSession(sessionId, solverId);

    await supabase
      .from("quiz_sessions")
      .update({ status: "FAILED", completed_at: new Date().toISOString() })
      .eq("id", sessionId);

    await this.saveSessionSummary(sessionId);
    await pendingChangeService.applyPendingChanges(session.target_id);

    return { session_status: "FAILED" };
  }
```

**Step 2: quiz.validator.ts'e rescue schema ekle**

```typescript
export const rescueQuizSchema = z.object({});

export type RescueQuizInput = z.infer<typeof rescueQuizSchema>;
```

**Step 3: quiz.controller.ts'e handler'lar ekle**

```typescript
export async function rescueQuizHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId;
    const sessionId = req.params.session_id as string;
    const data = await quizService.rescueWithSkip(sessionId, userId);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

export async function failQuizHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId;
    const sessionId = req.params.session_id as string;
    const data = await quizService.failSession(sessionId, userId);
    res.json(data);
  } catch (err) {
    next(err);
  }
}
```

**Step 4: quiz.routes.ts'e route'lar ekle**

`getSessionResultHandler` route'undan önce ekle (parameterized route'lardan önce olmalı):

```typescript
import {
  startQuizHandler,
  getCurrentQuestionHandler,
  answerQuestionHandler,
  getSessionResultHandler,
  getMatchQuizSummaryHandler,
  rescueQuizHandler,
  failQuizHandler,
} from "../controllers/quiz.controller.js";

// Mevcut route'ların arasına ekle (/:session_id'den önce değil, spesifik path olduğu için sorun yok):
router.post("/:session_id/rescue", rescueQuizHandler);
router.post("/:session_id/fail", failQuizHandler);
```

**Step 5: Commit**

```bash
git add server/src/services/quiz.service.ts server/src/controllers/quiz.controller.ts server/src/routes/quiz.routes.ts server/src/validators/quiz.validator.ts
git commit -m "feat(quiz): add rescue and fail endpoints for wrong answer recovery"
```

---

## Task 3: Backend — completeSession Response'una Badge Ekle

**Files:**
- Modify: `server/src/services/quiz.service.ts:483-491`

**Step 1: completeSession metodunda badge'i response'a ekle**

```typescript
// MEVCUT (satır 483-491):
  private async completeSession(session: SessionRow) {
    await this.createMatch(session.id, session.solver_id, session.target_id);
    await this.saveSessionSummary(session.id);
    await pendingChangeService.applyPendingChanges(session.target_id);
    return { is_correct: true, matched: true, session_status: "COMPLETED" };
  }

// YENİ:
  private async completeSession(session: SessionRow) {
    await this.createMatch(session.id, session.solver_id, session.target_id);
    await this.saveSessionSummary(session.id);
    await pendingChangeService.applyPendingChanges(session.target_id);
    const badge = await this.calculateBadge(session.id);
    return { is_correct: true, matched: true, session_status: "COMPLETED", badge };
  }
```

**Step 2: Commit**

```bash
git add server/src/services/quiz.service.ts
git commit -m "feat(quiz): include badge in completeSession response"
```

---

## Task 4: Backend — Power Kullanımında selected_answer Zorunluluğunu Kaldır

**Files:**
- Modify: `server/src/validators/quiz.validator.ts:7-13`

**Step 1: answerQuizSchema'da selected_answer'ı optional yap (power kullanımında göndermeyebilir)**

```typescript
// MEVCUT:
export const answerQuizSchema = z.object({
  selected_answer: z.number().int().min(1).max(4),
  power_used: z
    .enum(["ORACLE", "HALF", "SKIP", "SKIP_ALL", "TIME_EXTEND", "HINT"])
    .optional(),
  time_spent: z.number().int().min(0).max(120).optional(),
});

// YENİ:
export const answerQuizSchema = z.object({
  selected_answer: z.number().int().min(1).max(4).optional(),
  power_used: z
    .enum(["ORACLE", "HALF", "SKIP", "SKIP_ALL", "TIME_EXTEND", "HINT"])
    .optional(),
  time_spent: z.number().int().min(0).max(120).optional(),
}).refine(
  (data) => data.selected_answer != null || data.power_used != null,
  { message: "Either selected_answer or power_used is required" }
);
```

**Step 2: quiz.service.ts answerQuestion — power kullanımında selected_answer yoksa default 0 kullan**

`answerQuestion` metodunun başında (satır ~159):

```typescript
  async answerQuestion(
    sessionId: string,
    solverId: string,
    selectedAnswer: number | undefined,  // artık optional
    powerUsed?: PowerName,
    timeSpent?: number,
  ) {
```

Normal answer kısmında (satır ~325) guard ekle:

```typescript
    // ─── Normal answer (no power) ───
    if (selectedAnswer == null) {
      throw Errors.VALIDATION_ERROR({ selected_answer: "Required when no power is used" });
    }
    const isCorrect = selectedAnswer === currentQuestion.correct_answer;
```

**Step 3: quiz.controller.ts — selected_answer'ı optional olarak geçir**

```typescript
// answerQuestionHandler'da:
const { selected_answer, power_used, time_spent } = req.body as AnswerQuizInput;
const data = await quizService.answerQuestion(sessionId, userId, selected_answer, power_used, time_spent);
```

**Step 4: Commit**

```bash
git add server/src/validators/quiz.validator.ts server/src/services/quiz.service.ts server/src/controllers/quiz.controller.ts
git commit -m "fix(quiz): make selected_answer optional when using powers"
```

---

## Task 5: Flutter — QuizAnswerResponse Model Güncelleme

**Files:**
- Modify: `lib/data/models/quiz_model.dart:79-107`

**Step 1: QuizAnswerResponse'a canRescue ve badge ekle**

```dart
// MEVCUT QuizAnswerResponse (satır 79-107), şu alanları ekle:

@JsonSerializable()
class QuizAnswerResponse extends Equatable {
  @JsonKey(name: 'is_correct')
  final bool? isCorrect;
  final bool? matched;
  @JsonKey(name: 'next_question')
  final int? nextQuestion;
  @JsonKey(name: 'session_status')
  final String? sessionStatus;
  @JsonKey(name: 'power_result')
  final Map<String, dynamic>? powerResult;
  @JsonKey(name: 'awaiting_answer')
  final bool? awaitingAnswer;
  @JsonKey(name: 'can_rescue')
  final bool? canRescue;
  final String? badge;

  const QuizAnswerResponse({
    this.isCorrect,
    this.matched,
    this.nextQuestion,
    this.sessionStatus,
    this.powerResult,
    this.awaitingAnswer,
    this.canRescue,
    this.badge,
  });

  factory QuizAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerResponseFromJson(json);
  Map<String, dynamic> toJson() => _$QuizAnswerResponseToJson(this);

  @override
  List<Object?> get props => [isCorrect, sessionStatus, canRescue, badge];
}
```

**Step 2: build_runner ile .g.dart dosyasını regenerate et**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add lib/data/models/quiz_model.dart lib/data/models/quiz_model.g.dart
git commit -m "feat(quiz): add canRescue and badge fields to QuizAnswerResponse"
```

---

## Task 6: Flutter — Quiz Retrofit Service & Repository — Yeni Endpoint'ler

**Files:**
- Modify: `lib/core/network/services/quiz_service.dart`
- Modify: `lib/data/repositories/quiz_repository.dart`

**Step 1: quiz_service.dart'a rescue ve fail endpoint'lerini ekle**

```dart
  @POST('/quiz/{sessionId}/rescue')
  Future<QuizAnswerResponse> rescueWithSkip(
    @Path('sessionId') String sessionId,
  );

  @POST('/quiz/{sessionId}/fail')
  Future<QuizAnswerResponse> failSession(
    @Path('sessionId') String sessionId,
  );
```

**Step 2: build_runner ile .g.dart regenerate**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 3: quiz_repository.dart'a rescue ve fail metodlarını ekle**

```dart
  @override
  Future<Result<QuizAnswerResponse>> rescueWithSkip(String sessionId) async {
    try {
      final response = await _service.rescueWithSkip(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<QuizAnswerResponse>> failSession(String sessionId) async {
    try {
      final response = await _service.failSession(sessionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
```

**Step 4: Commit**

```bash
git add lib/core/network/services/quiz_service.dart lib/core/network/services/quiz_service.g.dart lib/data/repositories/quiz_repository.dart
git commit -m "feat(quiz): add rescue and fail API methods"
```

---

## Task 7: Flutter — QuizProvider — Rescue/Fail Metodları + isLoading Kaldır

**Files:**
- Modify: `lib/providers/quiz_provider.dart`

**Step 1: answer metodundan isLoading'i kaldır, rescue ve fail metodlarını ekle**

```dart
class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizState();

  Future<Result<QuizStartResponse>> startSession(String targetId) async {
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(quizRepositoryProvider).startSession(targetId);
    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          sessionId: data.sessionId,
          totalQuestions: data.totalQuestions,
          isLoading: false,
        );
        await fetchCurrentQuestion();
      case Failure(:final failure):
        state = state.copyWith(isLoading: false, failure: failure);
    }
    return result;
  }

  Future<void> fetchCurrentQuestion() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    state = state.copyWith(isLoading: true, failure: null);
    final result = await ref.read(quizRepositoryProvider).getCurrentQuestion(sessionId);
    result.when(
      success: (question) => state = state.copyWith(currentQuestion: question, isLoading: false),
      failure: (f) => state = state.copyWith(isLoading: false, failure: f),
    );
  }

  // answer artık isLoading set etmez — UI kendi _isSubmitting ile yönetir
  Future<Result<QuizAnswerResponse>> answer(int? selectedAnswer, {String? powerUsed, int? timeSpent}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).answerQuestion(
      sessionId,
      selectedAnswer: selectedAnswer,
      powerUsed: powerUsed,
      timeSpent: timeSpent,
    );
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (f) => state = state.copyWith(failure: f),
    );
    return result;
  }

  Future<Result<QuizAnswerResponse>> rescue() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).rescueWithSkip(sessionId);
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (f) => state = state.copyWith(failure: f),
    );
    return result;
  }

  Future<Result<QuizAnswerResponse>> fail() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    final result = await ref.read(quizRepositoryProvider).failSession(sessionId);
    result.when(
      success: (data) => state = state.copyWith(lastAnswer: data),
      failure: (f) => state = state.copyWith(failure: f),
    );
    return result;
  }

  Future<Result<QuizResultModel>> getResult() async {
    final sessionId = state.sessionId;
    if (sessionId == null) return Failure(const UnknownFailure(message: 'No active session'));
    return ref.read(quizRepositoryProvider).getSessionResult(sessionId);
  }

  void reset() {
    state = const QuizState();
  }
}
```

**Step 2: quiz_repository.dart answerQuestion — selectedAnswer'ı optional yap**

```dart
  @override
  Future<Result<QuizAnswerResponse>> answerQuestion(
    String sessionId, {
    int? selectedAnswer,  // artık optional
    String? powerUsed,
    int? timeSpent,
  }) async {
    try {
      final response = await _service.answerQuestion(sessionId, {
        if (selectedAnswer != null) 'selected_answer': selectedAnswer,
        if (powerUsed != null) 'power_used': powerUsed,
        if (timeSpent != null) 'time_spent': timeSpent,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
```

**Step 3: Commit**

```bash
git add lib/providers/quiz_provider.dart lib/data/repositories/quiz_repository.dart
git commit -m "feat(quiz): add rescue/fail provider methods, remove isLoading from answer"
```

---

## Task 8: Flutter — QuizTimer Refactor (pause/resume + addSeconds)

**Files:**
- Modify: `lib/features/quiz/widgets/quiz_timer.dart`

**Step 1: Timer'a pause, resume ve addSeconds desteği ekle**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class QuizTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeout;
  final VoidCallback? onWarning;
  final VoidCallback? onCritical;

  const QuizTimer({
    super.key,
    required this.seconds,
    required this.onTimeout,
    this.onWarning,
    this.onCritical,
  });

  @override
  State<QuizTimer> createState() => QuizTimerState();
}

// Public state — quiz_screen GlobalKey üzerinden erişebilir
class QuizTimerState extends State<QuizTimer> with TickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  bool _isPaused = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shakeAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  @override
  void didUpdateWidget(QuizTimer old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) {
      _timer?.cancel();
      _pulseController.reset();
      _shakeController.reset();
      _remaining = widget.seconds;
      _isPaused = false;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        _pulseController.stop();
        _shakeController.stop();
        widget.onTimeout();
      } else {
        setState(() => _remaining--);
        _updateAnimations();
      }
    });
  }

  void _updateAnimations() {
    if (_remaining == 10 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      widget.onWarning?.call();
    }
    if (_remaining == 5) {
      widget.onCritical?.call();
    }
    if (_remaining <= 5) {
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  // ── Public API ──────────────────────────────────────────────
  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  void addSeconds(int extra) {
    setState(() {
      _remaining += extra;
    });
  }

  Color get _barColor {
    if (_remaining <= 5) return AppColors.error;
    if (_remaining <= 10) return Colors.orange;
    return AppColors.secondary;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.seconds;
    final color = _barColor;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final dx = _remaining <= 5 ? _shakeAnimation.value : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm / 2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceInput,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _remaining <= 10 ? _pulseAnimation.value : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Text(
              '$_remaining s',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/quiz/widgets/quiz_timer.dart
git commit -m "feat(quiz): add pause/resume/addSeconds to QuizTimer"
```

---

## Task 9: Flutter — AnswerFeedbackOverlay — SKIP Rescue Kartı

**Files:**
- Modify: `lib/features/quiz/widgets/answer_feedback_overlay.dart`

**Step 1: Overlay'e rescue callback'leri ve SKIP teklif kartı ekle**

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';

class AnswerFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final String? correctAnswerText;
  final VoidCallback onComplete;
  // Rescue props (sadece yanlış cevap için)
  final bool canRescue;
  final int skipInventoryCount;
  final int skipDiamondCost;
  final VoidCallback? onRescue;
  final VoidCallback? onDeclineRescue;

  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    this.correctAnswerText,
    required this.onComplete,
    this.canRescue = false,
    this.skipInventoryCount = 0,
    this.skipDiamondCost = 20,
    this.onRescue,
    this.onDeclineRescue,
  });

  @override
  State<AnswerFeedbackOverlay> createState() => _AnswerFeedbackOverlayState();
}

class _AnswerFeedbackOverlayState extends State<AnswerFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Doğru cevap: hızlı göster ve otomatik kapat
    // Yanlış cevap + rescue: göster ama otomatik kapatma (kullanıcı karar verecek)
    // Yanlış cevap rescue yok: göster ve otomatik kapat
    final duration =
        widget.isCorrect ? const Duration(milliseconds: 800) : const Duration(milliseconds: 1000);

    _controller = AnimationController(vsync: this, duration: duration);

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      if (widget.isCorrect) {
        // Doğru cevap: kısa bekleme sonrası otomatik kapat
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) widget.onComplete();
        });
      } else if (!widget.canRescue) {
        // Yanlış + rescue yok: biraz bekle, sonra kapat
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onComplete();
        });
      }
      // Yanlış + rescue var: otomatik kapatma yok, kullanıcı buton tıklayacak
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isCorrect ? AppColors.success : AppColors.error;
    final icon = widget.isCorrect ? Icons.check_rounded : Icons.close_rounded;
    final label = widget.isCorrect ? 'Correct!' : 'Wrong!';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // SKIP Rescue kartı (sadece yanlış + rescue varsa)
                    if (!widget.isCorrect && widget.canRescue) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildRescueCard(theme),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRescueCard(ThemeData theme) {
    final hasInventory = widget.skipInventoryCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PowerIcon(type: PowerType.skip, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Skip ile Kurtul!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bu soruyu geçerek devam edebilirsin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // CTA: envanterde varsa yeşil, yoksa mor elmas fiyatı
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onRescue,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasInventory ? AppColors.success : AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                hasInventory
                    ? 'SKIP Kullan (×${widget.skipInventoryCount})'
                    : 'SKIP Satın Al — ${widget.skipDiamondCost} 💎',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: widget.onDeclineRescue,
            child: Text(
              'Vazgeç',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/quiz/widgets/answer_feedback_overlay.dart
git commit -m "feat(quiz): add SKIP rescue card to wrong answer overlay"
```

---

## Task 10: Flutter — PowerBar Refactor (usePower callback)

**Files:**
- Modify: `lib/features/quiz/widgets/power_bar.dart`

**Step 1: PowerBar'ın callback'ini değiştirme — mevcut yapı zaten uygun**

PowerBar'ın `onPowerUsed` callback'i zaten power name'i string olarak gönderiyor. Asıl sorun quiz_screen'deki çağrıda (`_answer(1, powerUsed: power)` satır 409). Bu Task 11'de düzeltilecek. PowerBar'da değişiklik gerekmez.

**Step 2: Commit — skip (değişiklik yok)**

---

## Task 11: Flutter — quiz_screen.dart Tam Refactor

**Files:**
- Modify: `lib/features/quiz/screens/quiz_screen.dart` (tam yeniden yazım)

Bu en büyük ve kritik task. Tüm logic sorunları burada düzeltilecek.

**Step 1: quiz_screen.dart'ı yeniden yaz**

Ana değişiklikler:
1. `_usePower(String power)` — ayrı metot, `_answer(1)` çağırmak yerine
2. `_onTimeout()` — sabit cevap yerine session fail veya rescue teklifi
3. Timer `GlobalKey<QuizTimerState>` ile kontrol (pause/resume/addSeconds)
4. Feedback overlay'de rescue props geçir
5. `_totalTimeSpent` sadece asıl cevap gönderiminde artır
6. `_powersUsed` sadece başarılı power dönüşünde artır
7. Badge'i backend'den al (frontend hesaplama kaldır)
8. Timer key'ini değiştirmek yerine `addSeconds()` kullan

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_feedback_overlay.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/features/quiz/screens/match_celebration_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String targetId;
  const QuizScreen({super.key, required this.targetId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _timerKey = GlobalKey<QuizTimerState>();
  final _stopwatch = Stopwatch();
  final _sessionStopwatch = Stopwatch();
  int _totalTimeSpent = 0;
  int _totalCorrect = 0;
  int _powersUsed = 0;
  int? _oracleSuggestedIndex;
  int? _selectedAnswerIndex;
  bool _isSubmitting = false;
  // Feedback state
  bool _showFeedback = false;
  bool _feedbackCorrect = false;
  bool _canRescue = false;
  String? _pendingSessionStatus;
  String? _pendingBadge;
  // Power result states
  List<int> _removedIndices = [];
  String? _hintText;
  // Celebration state
  bool _showCelebration = false;
  bool _celebrationMatched = false;
  String _celebrationBadge = 'none';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(exchangeProvider.notifier).fetchAll();
      await ref.read(quizProvider.notifier).startSession(widget.targetId);
      _startQuestionTimer();
      _sessionStopwatch.start();
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.quizStart,
        params: {
          AnalyticsEvents.paramPartnerId: widget.targetId,
        },
      );
    });
  }

  void _startQuestionTimer() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    ref.read(quizProvider.notifier).reset();
    super.dispose();
  }

  // ── Cevap seçimi (sadece highlight) ──────────────────────────
  void _selectAnswer(int index) {
    final wasSelected = _selectedAnswerIndex == index;
    setState(() {
      _selectedAnswerIndex = wasSelected ? null : index;
    });
    if (!wasSelected) {
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.quizAnswerSelect,
        params: {
          AnalyticsEvents.paramAnswerIndex: index,
          AnalyticsEvents.paramQuestionIndex:
              ref.read(quizProvider).currentQuestion?.questionNumber ?? 0,
        },
      );
    }
  }

  // ── Cevap gönderimi (onaylama sonrası) ───────────────────────
  Future<void> _submitAnswer() async {
    if (_selectedAnswerIndex == null || _isSubmitting) return;
    _timerKey.currentState?.pause();

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizAnswerConfirm,
      params: {
        AnalyticsEvents.paramAnswerIndex: _selectedAnswerIndex!,
        AnalyticsEvents.paramQuestionIndex:
            ref.read(quizProvider).currentQuestion?.questionNumber ?? 0,
      },
    );

    setState(() => _isSubmitting = true);

    _stopwatch.stop();
    final timeSpent = _stopwatch.elapsedMilliseconds ~/ 1000;
    _totalTimeSpent += timeSpent;

    final questionIndex = ref.read(quizProvider).currentQuestion?.questionNumber ?? 0;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizAnswer,
      params: {
        AnalyticsEvents.paramQuestionIndex: questionIndex,
        AnalyticsEvents.paramDurationMs: _stopwatch.elapsedMilliseconds,
      },
    );

    final result = await ref.read(quizProvider.notifier).answer(
          _selectedAnswerIndex!,
          timeSpent: timeSpent,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (data) => _handleAnswerResponse(data),
      failure: (_) {
        _timerKey.currentState?.resume();
      },
    );
  }

  // ── Power kullanımı (cevap göndermeden) ──────────────────────
  Future<void> _usePower(String power) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(quizProvider.notifier).answer(
          null, // selected_answer yok
          powerUsed: power,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (data) {
        if (data.awaitingAnswer == true) {
          // Power efekti: ORACLE, HALF, HINT, TIME_EXTEND
          _powersUsed++;
          final powerResult = data.powerResult;
          if (powerResult != null) {
            setState(() {
              if (powerResult.containsKey('suggested_answer_index')) {
                _oracleSuggestedIndex = powerResult['suggested_answer_index'] as int?;
              }
              if (powerResult.containsKey('removed_indices')) {
                _removedIndices = (powerResult['removed_indices'] as List).cast<int>();
              }
              if (powerResult.containsKey('extra_seconds')) {
                final extra = powerResult['extra_seconds'] as int;
                _timerKey.currentState?.addSeconds(extra);
              }
              if (powerResult.containsKey('hint_text')) {
                _hintText = powerResult['hint_text'] as String?;
              }
            });
          }
        } else {
          // SKIP veya SKIP_ALL — direkt sonuç
          _powersUsed++;
          if (data.isCorrect == true) _totalCorrect++;
          _handleSessionTransition(data.sessionStatus, data.badge);
        }
      },
      failure: (_) {},
    );
  }

  // ── Cevap response handler ──────────────────────────────────
  void _handleAnswerResponse(dynamic data) {
    if (data.awaitingAnswer == true) {
      // Bu durumda power sonrası cevap bekleniyor (normalde _usePower'dan gelir)
      return;
    }

    final isCorrect = data.isCorrect == true;
    if (isCorrect) _totalCorrect++;

    // Completion analytics
    if (data.sessionStatus == 'COMPLETED' || (data.sessionStatus == 'FAILED')) {
      _sessionStopwatch.stop();
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.quizComplete,
        params: {
          AnalyticsEvents.paramScore: _totalCorrect,
          AnalyticsEvents.paramTotalDurationMs: _sessionStopwatch.elapsedMilliseconds,
        },
      );
    }

    // Feedback overlay göster
    setState(() {
      _feedbackCorrect = isCorrect;
      _canRescue = data.canRescue == true;
      _pendingSessionStatus = isCorrect ? data.sessionStatus : null;
      _pendingBadge = data.badge;
      _showFeedback = true;
    });
  }

  // ── Feedback tamamlandı (doğru cevap sonrası otomatik veya yanlış cevap rescue yok) ──
  void _onFeedbackComplete() {
    if (!mounted) return;
    final status = _pendingSessionStatus;
    final badge = _pendingBadge;
    _resetQuestionState();

    if (status == 'COMPLETED') {
      _showGamifiedResult(matched: true, badge: badge ?? 'none');
    } else {
      // Doğru cevap, sonraki soruya geç
      ref.read(quizProvider.notifier).fetchCurrentQuestion();
      _startQuestionTimer();
    }
  }

  // ── SKIP Rescue — kullanıcı kurtulmayı kabul etti ───────────
  Future<void> _onRescue() async {
    setState(() => _isSubmitting = true);

    final result = await ref.read(quizProvider.notifier).rescue();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (data) {
        _powersUsed++;
        // Yanlış cevabı override ettik, doğru sayılıyor
        // _totalCorrect zaten artırılmadı (yanlıştı), şimdi artır
        _totalCorrect++;
        _resetQuestionState();

        if (data.sessionStatus == 'COMPLETED') {
          _showGamifiedResult(matched: true, badge: data.badge ?? 'none');
        } else {
          ref.read(quizProvider.notifier).fetchCurrentQuestion();
          _startQuestionTimer();
        }
      },
      failure: (_) {
        // Rescue başarısız (elmas yetersiz vs), session'ı fail yap
        _onDeclineRescue();
      },
    );
  }

  // ── SKIP Rescue — kullanıcı vazgeçti ────────────────────────
  Future<void> _onDeclineRescue() async {
    await ref.read(quizProvider.notifier).fail();

    if (!mounted) return;
    _resetQuestionState();

    _sessionStopwatch.stop();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizComplete,
      params: {
        AnalyticsEvents.paramScore: _totalCorrect,
        AnalyticsEvents.paramTotalDurationMs: _sessionStopwatch.elapsedMilliseconds,
      },
    );

    _showGamifiedResult(matched: false, badge: 'none');
  }

  // ── Timer bitti ─────────────────────────────────────────────
  Future<void> _onTimeout() async {
    // Süre doldu — session'ı fail yap
    _stopwatch.stop();
    await ref.read(quizProvider.notifier).fail();

    if (!mounted) return;
    _sessionStopwatch.stop();

    _showGamifiedResult(matched: false, badge: 'none');
  }

  // ── Session sonucu geçişi ───────────────────────────────────
  void _handleSessionTransition(String? status, String? badge) {
    if (status == 'COMPLETED') {
      _showGamifiedResult(matched: true, badge: badge ?? 'none');
    } else if (status == 'FAILED') {
      _showGamifiedResult(matched: false, badge: 'none');
    } else {
      // IN_PROGRESS — sonraki soruya geç
      _resetQuestionState();
      ref.read(quizProvider.notifier).fetchCurrentQuestion();
      _startQuestionTimer();
    }
  }

  void _resetQuestionState() {
    setState(() {
      _showFeedback = false;
      _canRescue = false;
      _pendingSessionStatus = null;
      _pendingBadge = null;
      _oracleSuggestedIndex = null;
      _selectedAnswerIndex = null;
      _removedIndices = [];
      _hintText = null;
    });
  }

  void _showGamifiedResult({required bool matched, required String badge}) {
    _stopwatch.stop();
    setState(() {
      _showCelebration = true;
      _celebrationMatched = matched;
      _celebrationBadge = badge;
    });
  }

  Future<void> _confirmExit() async {
    final nav = ref.read(navigationServiceProvider);
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizExitAttempt,
      params: {
        AnalyticsEvents.paramQuestionIndex:
            ref.read(quizProvider).currentQuestion?.questionNumber ?? 0,
      },
    );
    final confirm = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'quiz_exit',
        title: 'Emin misin?',
        message: 'Matchleşme şansından vazgeçiyorsun!',
        confirmText: 'Vazgeç',
        cancelText: 'Devam Et',
        isDestructive: true,
      ),
    );
    if (confirm == true && mounted) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.quizExitConfirm);
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.quizAbandon,
        params: {
          AnalyticsEvents.paramQuestionIndex:
              ref.read(quizProvider).currentQuestion?.questionNumber ?? 0,
        },
      );
      nav.go(RouteNames.discover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final theme = Theme.of(context);
    final question = quiz.currentQuestion;

    if (_showCelebration) {
      final nav = ref.read(navigationServiceProvider);
      return MatchCelebrationScreen(
        matched: _celebrationMatched,
        totalCorrect: _totalCorrect,
        totalQuestions: quiz.totalQuestions,
        totalTimeSpent: _totalTimeSpent,
        powersUsed: _powersUsed,
        performanceBadge: _celebrationBadge,
        onStartChat: _celebrationMatched
            ? () => nav.go(RouteNames.matches)
            : null,
        onGoBack: () => nav.go(RouteNames.discover),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmExit();
      },
      child: AppScaffold(
        title: question != null
            ? '${question.questionNumber}/${question.totalQuestions}'
            : '',
        leading: IconButton(
          icon: QIcon(QIcons.icX, size: 24),
          onPressed: _confirmExit,
        ),
        padding: EdgeInsets.zero,
        isLoading: question == null,
        body: question == null
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        QuizTimer(
                          key: _timerKey,
                          seconds: question.timeLimitSeconds,
                          onTimeout: _onTimeout,
                          onWarning: () {
                            AnalyticsManager.instance.logEvent(
                              AnalyticsEvents.quizTimerWarning,
                              params: {
                                AnalyticsEvents.paramQuestionIndex:
                                    question.questionNumber,
                                AnalyticsEvents.paramSecondsRemaining: 10,
                              },
                            );
                          },
                          onCritical: () {
                            AnalyticsManager.instance.logEvent(
                              AnalyticsEvents.quizTimerCritical,
                              params: {
                                AnalyticsEvents.paramQuestionIndex:
                                    question.questionNumber,
                                AnalyticsEvents.paramSecondsRemaining: 5,
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          question.questionText,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (_oracleSuggestedIndex != null)
                          _buildPowerBanner(
                            theme,
                            icon: Icons.auto_awesome,
                            text: context.tr('power_oracle_desc'),
                          ),
                        if (_hintText != null && _hintText!.isNotEmpty)
                          _buildPowerBanner(
                            theme,
                            icon: Icons.lightbulb_outline,
                            text: _hintText!,
                            color: Colors.amber,
                          ),
                        ...question.answers.map((a) {
                          final isRemoved = _removedIndices.contains(a.index);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AnswerButton(
                              text: a.text,
                              onTap: () {
                                if (!isRemoved) _selectAnswer(a.index);
                              },
                              isSelected: _selectedAnswerIndex == a.index,
                              isOracleSuggested: _oracleSuggestedIndex == a.index,
                              isDisabled: isRemoved,
                            ),
                          );
                        }),
                        if (_selectedAnswerIndex != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitAnswer,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                              child: _isSubmitting
                                  ? AppLoadingWidget.small()
                                  : Text(
                                      context.tr('quiz_confirm_answer'),
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        const Spacer(),
                        PowerBar(
                          sessionId: quiz.sessionId!,
                          hasHint: question.hasHint,
                          onPowerUsed: _usePower,
                        ),
                      ],
                    ),
                  ),
                  if (_showFeedback)
                    AnswerFeedbackOverlay(
                      isCorrect: _feedbackCorrect,
                      onComplete: _onFeedbackComplete,
                      canRescue: _canRescue,
                      skipInventoryCount:
                          ref.read(exchangeProvider).getCount('SKIP'),
                      skipDiamondCost: _getSkipCost(),
                      onRescue: _onRescue,
                      onDeclineRescue: _onDeclineRescue,
                    ),
                ],
              ),
      ),
    );
  }

  int _getSkipCost() {
    final rates = ref.read(exchangeProvider).rates;
    if (rates != null) {
      final skipPower = rates.powers.where((p) => p.name == 'SKIP').firstOrNull;
      if (skipPower != null) return skipPower.baseCost;
    }
    return 20; // default fallback
  }

  Widget _buildPowerBanner(
    ThemeData theme, {
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/quiz/screens/quiz_screen.dart
git commit -m "refactor(quiz): complete quiz screen logic overhaul — powers, timer, rescue, badge"
```

---

## Task 12: Backend Test & Flutter Build Verification

**Step 1: Backend build kontrolü**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2/server && npm run build
```

Expected: No TypeScript errors

**Step 2: Flutter analyze**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && flutter analyze
```

Expected: No errors (warnings OK)

**Step 3: Fix any issues found, then commit**

```bash
git add -A && git commit -m "fix: resolve build errors from quiz stabilization"
```

---

## Task Dependency Graph

```
Task 1 (backend wrong answer) ─┐
Task 2 (rescue/fail endpoints) ─┤
Task 3 (badge in response)     ─┤── Backend ready
Task 4 (optional selected_ans) ─┘
                                 │
Task 5 (Flutter models) ────────┤
Task 6 (Flutter API layer) ─────┤── API layer ready
Task 7 (Flutter provider) ──────┘
                                 │
Task 8 (Timer refactor) ────────┤
Task 9 (Feedback overlay) ──────┤── Widgets ready
                                 │
Task 10 (PowerBar — skip) ──────┤
Task 11 (quiz_screen refactor) ─┘── UI complete
                                 │
Task 12 (Build verification) ───┘── Done
```

Tasks 1-4 bağımsız → paralel yapılabilir.
Tasks 5-7 backend'e bağımlı → backend sonrası.
Tasks 8-9 bağımsız widget'lar → paralel.
Task 11 tüm widget + provider'lara bağımlı → en son.
