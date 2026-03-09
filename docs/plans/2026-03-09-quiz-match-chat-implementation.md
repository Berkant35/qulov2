# Quiz → Match → Chat Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Discover → Quiz → Match → Chat akışını uçtan uca çalışır hale getir, UX iyileştirmeleri ve chat yeni özelliklerini ekle.

**Architecture:** Önce DB blocker'ları düzelt, sonra quiz UX overhaul (seç+onayla, timer gerilim, çıkış koruması, feedback animasyonları), match kutlama ekranı, son olarak chat enhancements (typing, reactions, delete, voice, chat questions).

**Tech Stack:** Flutter + Riverpod + GoRouter (mobile), Node.js + Express + TypeScript (backend), Supabase PostgreSQL + Realtime (DB), Firebase FCM (push)

---

## Phase 1: Blocker Fixleri

### Task 1: Migration 015 — quiz_sessions.total_questions

**Files:**
- Create: `supabase/migrations/015_quiz_session_total_questions.sql`

**Step 1: Migration dosyasını oluştur**

```sql
-- 015_quiz_session_total_questions.sql
-- Quiz session'a total_questions kolonu ekle (quiz.service.ts startSession insert'te kullanıyor)

ALTER TABLE quiz_sessions ADD COLUMN total_questions INT NOT NULL DEFAULT 0;
```

**Step 2: Commit**

```bash
git add supabase/migrations/015_quiz_session_total_questions.sql
git commit -m "fix: add total_questions column to quiz_sessions (migration 015)"
```

> **NOT:** Bu migration'ı ve 014'ü Supabase SQL Editor'dan manuel çalıştır.

---

### Task 2: Notification service — quiz_started push'unu kaldır, match push'u badge ile zenginleştir

**Files:**
- Modify: `server/src/services/quiz.service.ts:104-108` (quiz_started push kaldır)
- Modify: `server/src/services/quiz.service.ts:421-444` (createMatch — badge bilgisi ekle)
- Modify: `server/src/services/notification.service.ts:29-120` (match push template'e badge desteği)

**Step 1: quiz.service.ts — startSession'dan quiz_started push'unu kaldır**

`quiz.service.ts` içinde `startSession` metodunda, session oluşturulduktan sonra target'a gönderilen push'u kaldır:

```typescript
// KALDIR: Bu satırları sil (yaklaşık lines 104-108)
// await NotificationService.sendPush(targetId, "quiz_started", {
//   solver_name: solverName,
// }, `/discover`);
```

**Step 2: quiz.service.ts — createMatch'e badge bilgisi ekle**

`createMatch` private metodunu güncelle. Session bilgisinden badge hesapla ve push'a ekle:

```typescript
private async createMatch(solverId: string, targetId: string, sessionId: string) {
  const [user1, user2] = [solverId, targetId].sort();

  const { error: matchError } = await supabase
    .from("matches")
    .insert({ user1_id: user1, user2_id: user2 });

  if (matchError && matchError.code !== "23505") {
    console.error("[quiz] Match insert error:", matchError);
  }

  // Badge hesapla
  const badge = await this.calculateBadge(sessionId);

  // Her iki tarafa push — target'a badge bilgisiyle
  await NotificationService.sendPush(targetId, "new_match", {
    badge,
  }, "/matches");

  await NotificationService.sendPush(solverId, "new_match", {}, "/matches");
}

private async calculateBadge(sessionId: string): Promise<string> {
  const { data: session } = await supabase
    .from("quiz_sessions")
    .select("total_time_spent, powers_used, total_questions")
    .eq("id", sessionId)
    .single();

  if (!session) return "none";

  const { data: answers } = await supabase
    .from("quiz_answers")
    .select("is_correct, power_used")
    .eq("session_id", sessionId);

  if (!answers) return "none";

  const allCorrect = answers.every((a: any) => a.is_correct);
  const totalPowers = answers.filter((a: any) => a.power_used).length;
  const totalTime = session.total_time_spent || 0;

  if (allCorrect && totalPowers === 0) return "flawless";
  if (totalTime < session.total_questions * 15) return "speed_solver";
  if (totalPowers >= 3) return "power_master";
  if (allCorrect) return "determined";
  return "none";
}
```

**Step 3: notification.service.ts — match push template'e badge desteği**

`NOTIFICATION_TEMPLATES` içinde `new_match` template'ini güncelle:

```typescript
new_match: {
  en: {
    title: "New Match! 🎉",
    body: (p: any) => p.badge && p.badge !== "none"
      ? `Someone solved your quiz with ${p.badge.toUpperCase()} badge! You have a new match!`
      : "You have a new match! Start chatting now.",
  },
  tr: {
    title: "Yeni Eşleşme! 🎉",
    body: (p: any) => p.badge && p.badge !== "none"
      ? `Birisi sorularını ${p.badge.toUpperCase()} badge ile çözdü! Yeni eşleşmen var!`
      : "Yeni bir eşleşmen var! Hemen sohbete başla.",
  },
},
```

**Step 4: Commit**

```bash
git add server/src/services/quiz.service.ts server/src/services/notification.service.ts
git commit -m "feat: remove quiz_started push, enrich match push with badge info"
```

---

## Phase 2: Quiz UX Overhaul

### Task 3: Answer Button — Seç + Onayla Mekaniği

**Files:**
- Modify: `lib/features/quiz/widgets/answer_button.dart` (selectable mode ekle)
- Modify: `lib/features/quiz/screens/quiz_screen.dart` (seç+onayla akışı)

**Step 1: answer_button.dart — isSelected state ekle**

AnswerButton'a `isSelected` prop'u ekle. Seçiliyken mor highlight, tıklanınca sadece "seç" callback'i çağrılsın:

```dart
class AnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isDisabled;
  final bool isOracleSuggested;
  final bool isSelected; // YENİ

  const AnswerButton({
    super.key,
    required this.text,
    this.onTap,
    this.isDisabled = false,
    this.isOracleSuggested = false,
    this.isSelected = false, // YENİ
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor = isSelected
        ? AppColors.primary
        : isOracleSuggested
            ? AppColors.primary.withValues(alpha: 0.6)
            : AppColors.border;

    final bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.15)
        : isDisabled
            ? AppColors.surfaceInput
            : AppColors.surface;

    final borderWidth = isSelected ? 2.5 : isOracleSuggested ? 2.0 : 1.0;

    Widget button = GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDisabled ? AppColors.textHint : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (isOracleSuggested) {
      button = _OraclePulseWrapper(child: button);
    }

    return button;
  }
}
```

**Step 2: quiz_screen.dart — seç+onayla akışı**

State'e `_selectedAnswerIndex` ekle. Cevap butonlarına tıklayınca seç, "Cevapla" butonuyla gönder:

quiz_screen.dart state variables'a ekle:
```dart
int? _selectedAnswerIndex;
```

Build metodu içinde answer butonları bölümünü güncelle (yaklaşık lines 251-258):
```dart
// Cevap butonları
...question.answers.map((a) => Padding(
  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
  child: AnswerButton(
    text: a.text,
    isSelected: _selectedAnswerIndex == a.index,
    isOracleSuggested: _oracleSuggestedIndex == a.index,
    isDisabled: state.isLoading,
    onTap: () {
      setState(() => _selectedAnswerIndex = a.index);
    },
  ),
)),

// Cevapla butonu — sadece bir şık seçiliyken görünür
if (_selectedAnswerIndex != null)
  Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: ElevatedButton(
      onPressed: state.isLoading ? null : () => _submitAnswer(_selectedAnswerIndex!),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
      ),
      child: state.isLoading
          ? const AppLoadingWidget.small()
          : const Text('Cevapla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  ),
```

`_answer` metodunu `_submitAnswer` olarak yeniden adlandır ve `_selectedAnswerIndex`'i resetle:
```dart
Future<void> _submitAnswer(int selectedAnswer) async {
  final timeSpent = _stopwatch.elapsed.inSeconds;
  _stopwatch.reset();

  setState(() => _selectedAnswerIndex = null); // Reset selection

  // ... mevcut answer logic
}
```

Her yeni soru yüklendiğinde `_selectedAnswerIndex`'i null'a resetle.

**Step 3: `flutter analyze` çalıştır, hata olmadığını doğrula**

```bash
dart analyze lib/features/quiz/
```

**Step 4: Commit**

```bash
git add lib/features/quiz/widgets/answer_button.dart lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat(quiz): add select+confirm answer mechanism"
```

---

### Task 4: Quiz Timer — Gerilim Katmanları

**Files:**
- Modify: `lib/features/quiz/widgets/quiz_timer.dart`

**Step 1: Timer'a renk geçişi, pulse ve shake ekle**

quiz_timer.dart'ı tamamen güncelle:

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/theme.dart';

class QuizTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeout;

  const QuizTimer({super.key, required this.seconds, required this.onTimeout});

  @override
  State<QuizTimer> createState() => _QuizTimerState();
}

class _QuizTimerState extends State<QuizTimer> with TickerProviderStateMixin {
  late int _remaining;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

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
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _startTimer();
  }

  @override
  void didUpdateWidget(QuizTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _remaining = widget.seconds;
      _pulseController.stop();
      _shakeController.stop();
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _remaining--);

      // Son 10sn: pulse başlat
      if (_remaining == 10) {
        _pulseController.repeat(reverse: true);
      }

      // Son 5sn: shake başlat
      if (_remaining <= 5 && _remaining > 0) {
        _shakeController.forward().then((_) {
          if (mounted) _shakeController.reverse();
        });
      }

      if (_remaining <= 0) {
        widget.onTimeout();
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.seconds;
    final isWarning = _remaining <= 10;
    final isCritical = _remaining <= 5;

    final barColor = isCritical
        ? AppColors.error
        : isWarning
            ? Colors.orange
            : AppColors.secondary;

    Widget timerContent = Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceInput,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isWarning ? _pulseAnimation.value : 1.0,
              child: Text(
                '$_remaining',
                style: TextStyle(
                  color: barColor,
                  fontSize: 14,
                  fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ],
    );

    if (isCritical) {
      return AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: timerContent,
          );
        },
      );
    }

    return timerContent;
  }
}
```

> **NOT:** `AnimatedBuilder` Flutter 3.x+'da var. Eğer projede eski Flutter varsa `AnimatedWidget` veya `Builder` pattern kullan.

**Step 2: `flutter analyze` çalıştır**

```bash
dart analyze lib/features/quiz/widgets/quiz_timer.dart
```

**Step 3: Commit**

```bash
git add lib/features/quiz/widgets/quiz_timer.dart
git commit -m "feat(quiz): add timer tension layers — pulse, shake, color transitions"
```

---

### Task 5: Quiz — Çıkış Koruması

**Files:**
- Modify: `lib/features/quiz/screens/quiz_screen.dart`

**Step 1: PopScope ile back koruması ekle**

quiz_screen.dart'ın build metodunda `AppScaffold`'u `PopScope` ile sar:

```dart
@override
Widget build(BuildContext context) {
  final state = ref.watch(quizProvider);

  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final shouldPop = await ref.read(navigationServiceProvider).showAppDialog<bool>(
        ConfirmDialog(
          title: 'Emin misin?',
          message: 'Matchleşme şansından vazgeçiyorsun!',
          confirmText: 'Vazgeç',
          cancelText: 'Devam Et',
          isDestructive: true,
        ),
      );
      if (shouldPop == true && context.mounted) {
        ref.read(navigationServiceProvider).pop();
      }
    },
    child: AppScaffold(
      // ... mevcut scaffold içeriği
    ),
  );
}
```

Analytics'e `quiz_abandon` event'ini çıkış onaylanınca logla:

```dart
if (shouldPop == true && context.mounted) {
  ref.read(analyticsManagerProvider).logEvent('quiz_abandon', {
    'question_index': state.currentQuestion?.questionNumber ?? 0,
  });
  ref.read(navigationServiceProvider).pop();
}
```

**Step 2: Commit**

```bash
git add lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat(quiz): add exit protection with confirm dialog"
```

---

### Task 6: Quiz — Cevap Feedback Animasyonları

**Files:**
- Create: `lib/features/quiz/widgets/answer_feedback_overlay.dart`
- Modify: `lib/features/quiz/screens/quiz_screen.dart`

**Step 1: Feedback overlay widget oluştur**

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/theme.dart';

class AnswerFeedbackOverlay extends StatefulWidget {
  final bool isCorrect;
  final String? correctAnswerText;
  final VoidCallback onComplete;

  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    this.correctAnswerText,
    required this.onComplete,
  });

  @override
  State<AnswerFeedbackOverlay> createState() => _AnswerFeedbackOverlayState();
}

class _AnswerFeedbackOverlayState extends State<AnswerFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    final duration = widget.isCorrect ? 800 : 1500;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );

    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: widget.isCorrect ? 200 : 800), () {
        if (mounted) widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isCorrect
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      widget.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      size: 48,
                      color: widget.isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isCorrect ? 'Correct!' : 'Wrong!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                  if (!widget.isCorrect && widget.correctAnswerText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Doğru cevap: ${widget.correctAnswerText}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

**Step 2: quiz_screen.dart — feedback overlay'ı entegre et**

State'e `_showFeedback` ve `_feedbackCorrect` ekle:

```dart
bool _showFeedback = false;
bool _feedbackCorrect = false;
String? _correctAnswerText;
```

`_submitAnswer` içinde, cevap sonrası feedback göster:

```dart
Future<void> _submitAnswer(int selectedAnswer) async {
  final timeSpent = _stopwatch.elapsed.inSeconds;
  _stopwatch.reset();

  final currentQuestion = ref.read(quizProvider).currentQuestion;
  setState(() => _selectedAnswerIndex = null);

  await ref.read(quizProvider.notifier).answer(selectedAnswer, timeSpent: timeSpent);

  final answerResult = ref.read(quizProvider).lastAnswer;
  if (answerResult == null) return;

  // Feedback göster
  setState(() {
    _showFeedback = true;
    _feedbackCorrect = answerResult.isCorrect ?? false;
    // Yanlışsa doğru cevabı bul (backend döndürmüyorsa bu bilgiyi)
  });

  // Feedback tamamlanınca (_onFeedbackComplete callback'i tetiklenince)
  // sonraki adıma geç
}

void _onFeedbackComplete() {
  setState(() => _showFeedback = false);

  final lastAnswer = ref.read(quizProvider).lastAnswer;
  if (lastAnswer == null) return;

  if (lastAnswer.sessionStatus == 'COMPLETED' || lastAnswer.sessionStatus == 'FAILED') {
    _showMatchResult(lastAnswer);
  } else {
    // Sonraki soru zaten provider'da yüklendi
    _stopwatch.start();
  }
}
```

Build metodu body'sine Stack ile overlay ekle:

```dart
body: Stack(
  children: [
    // Mevcut quiz content
    Column(children: [ /* timer, question, answers, powerbar */ ]),

    // Feedback overlay
    if (_showFeedback)
      AnswerFeedbackOverlay(
        isCorrect: _feedbackCorrect,
        correctAnswerText: _correctAnswerText,
        onComplete: _onFeedbackComplete,
      ),
  ],
),
```

**Step 3: `flutter analyze` çalıştır**

```bash
dart analyze lib/features/quiz/
```

**Step 4: Commit**

```bash
git add lib/features/quiz/widgets/answer_feedback_overlay.dart lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat(quiz): add correct/wrong answer feedback animations"
```

---

### Task 7: Discover → Quiz Zoom-In Geçiş

**Files:**
- Modify: `lib/features/discover/screens/discover_screen.dart:437-459` (solve button)
- Modify: `lib/routing/app_routes.dart` (quiz route transition)

**Step 1: app_routes.dart — quiz route'a custom page transition ekle**

Quiz route tanımını güncelle:

```dart
GoRoute(
  parentNavigatorKey: rootNavigatorKey,
  path: '/quiz/:targetId',
  name: RouteNames.quiz,
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: QuizScreen(targetId: state.pathParameters['targetId']!),
    transitionDuration: const Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  ),
),
```

**Step 2: Commit**

```bash
git add lib/routing/app_routes.dart
git commit -m "feat(discover): add zoom-in transition to quiz screen"
```

---

## Phase 3: Match Kutlama

### Task 8: Match Celebration Screen (Badge Odaklı)

**Files:**
- Create: `lib/features/quiz/screens/match_celebration_screen.dart`
- Modify: `lib/features/quiz/screens/quiz_screen.dart` (result dialog → celebration screen)

**Step 1: match_celebration_screen.dart oluştur**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qulo_v2/core/theme/theme.dart';

class MatchCelebrationScreen extends StatefulWidget {
  final bool matched;
  final int totalCorrect;
  final int totalQuestions;
  final int totalTimeSpent;
  final int powersUsed;
  final String performanceBadge;
  final String? targetPhotoUrl;
  final String? myPhotoUrl;
  final VoidCallback? onStartChat;
  final VoidCallback onGoBack;

  const MatchCelebrationScreen({
    super.key,
    required this.matched,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.totalTimeSpent,
    required this.powersUsed,
    required this.performanceBadge,
    this.targetPhotoUrl,
    this.myPhotoUrl,
    this.onStartChat,
    required this.onGoBack,
  });

  @override
  State<MatchCelebrationScreen> createState() => _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late AnimationController _photoController;
  late AnimationController _confettiController;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeOpacity;
  late Animation<double> _photoSlide;
  late Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _badgeScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );
    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: const Interval(0.0, 0.3)),
    );

    _photoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _photoSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _photoController, curve: Curves.easeOutBack),
    );
    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _photoController, curve: Curves.easeIn),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Sıralı animasyon
    if (widget.matched) {
      _confettiController.forward();
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _badgeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _photoController.forward();
    });
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _photoController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeConfig = _getBadgeConfig(widget.performanceBadge);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Badge animasyonu
              AnimatedBuilder(
                animation: _badgeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _badgeOpacity.value,
                    child: Transform.scale(
                      scale: _badgeScale.value,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: badgeConfig.gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeConfig.icon, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  badgeConfig.label,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.matched) ...[
                            const SizedBox(height: 16),
                            Text(
                              "It's a Match!",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Quiz Failed',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Fotoğraflar (match ise)
              if (widget.matched)
                AnimatedBuilder(
                  animation: _photoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _contentOpacity.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(-_photoSlide.value, 0),
                            child: _buildPhoto(widget.myPhotoUrl),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.favorite, color: AppColors.error, size: 32),
                          const SizedBox(width: 16),
                          Transform.translate(
                            offset: Offset(_photoSlide.value, 0),
                            child: _buildPhoto(widget.targetPhotoUrl),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Stats
              AnimatedBuilder(
                animation: _photoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentOpacity.value,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('${widget.totalCorrect}/${widget.totalQuestions}', 'Doğru'),
                          _buildStat('${widget.totalTimeSpent}s', 'Süre'),
                          if (widget.powersUsed > 0)
                            _buildStat('${widget.powersUsed}', 'Güç'),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Butonlar
              AnimatedBuilder(
                animation: _photoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentOpacity.value,
                    child: Column(
                      children: [
                        if (widget.matched && widget.onStartChat != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onStartChat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              child: const Text('Send a Message',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.onGoBack,
                            child: const Text('Go Back'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(String? url) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
        child: url != null
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
            : const Icon(Icons.person, size: 40, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  _BadgeCelebrationConfig _getBadgeConfig(String badge) {
    switch (badge) {
      case 'flawless':
        return _BadgeCelebrationConfig(
          label: 'FLAWLESS',
          icon: Icons.stars_rounded,
          gradientColors: [Colors.amber, Colors.orange],
        );
      case 'speed_solver':
        return _BadgeCelebrationConfig(
          label: 'SPEED SOLVER',
          icon: Icons.bolt_rounded,
          gradientColors: [Colors.blue, Colors.cyan],
        );
      case 'power_master':
        return _BadgeCelebrationConfig(
          label: 'POWER MASTER',
          icon: Icons.auto_awesome,
          gradientColors: [AppColors.primary, Colors.deepPurple],
        );
      case 'determined':
        return _BadgeCelebrationConfig(
          label: 'DETERMINED',
          icon: Icons.psychology_rounded,
          gradientColors: [Colors.green, Colors.teal],
        );
      default:
        return _BadgeCelebrationConfig(
          label: widget.matched ? 'MATCHED' : 'FAILED',
          icon: widget.matched ? Icons.favorite : Icons.close,
          gradientColors: widget.matched
              ? [AppColors.primary, Colors.pink]
              : [AppColors.error, Colors.red],
        );
    }
  }
}

class _BadgeCelebrationConfig {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;

  const _BadgeCelebrationConfig({
    required this.label,
    required this.icon,
    required this.gradientColors,
  });
}
```

**Step 2: quiz_screen.dart — result dialog yerine celebration screen göster**

`_showGamifiedResult` metodunu güncelle:

```dart
void _showMatchResult(QuizAnswerResponse answer) {
  final matched = answer.matched ?? false;

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => MatchCelebrationScreen(
        matched: matched,
        totalCorrect: _totalCorrect,
        totalQuestions: ref.read(quizProvider).totalQuestions,
        totalTimeSpent: _sessionStopwatch.elapsed.inSeconds,
        powersUsed: _powersUsed,
        performanceBadge: _determineBadge(),
        onStartChat: matched ? () {
          // Chat'e git — matchId lazım (backend'den dönmeli)
          // Şimdilik pop yapıp matches ekranına yönlendir
          ref.read(navigationServiceProvider).go(RouteNames.matches);
        } : null,
        onGoBack: () {
          ref.read(navigationServiceProvider).pop();
        },
      ),
    ),
  );
}
```

**Step 3: Commit**

```bash
git add lib/features/quiz/screens/match_celebration_screen.dart lib/features/quiz/screens/quiz_screen.dart
git commit -m "feat(quiz): add badge-focused match celebration full screen"
```

---

## Phase 4: Chat Enhancements

### Task 9: Migration 016 — Chat Yeni Tabloları

**Files:**
- Create: `supabase/migrations/016_chat_enhancements.sql`

**Step 1: Migration oluştur**

```sql
-- 016_chat_enhancements.sql
-- Chat sistemi yeni özellikler: sorular, reactions, silme, ses mesajı

-- Chat içi sorular
CREATE TABLE chat_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  question_text TEXT NOT NULL,
  option_a TEXT NOT NULL,
  option_b TEXT NOT NULL,
  correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('A', 'B')),
  has_unmatch_risk BOOLEAN NOT NULL DEFAULT false,
  diamond_cost INT NOT NULL DEFAULT 5,
  answered_option CHAR(1) CHECK (answered_option IN ('A', 'B')),
  is_correct BOOLEAN,
  answered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Message reactions
CREATE TABLE message_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);

-- Messages tablosuna soft delete + ses mesajı
ALTER TABLE messages ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE messages ADD COLUMN audio_url TEXT;
ALTER TABLE messages ADD COLUMN audio_duration_seconds INT;

-- Chat soru günlük limit takibi
ALTER TABLE chat_questions ADD COLUMN question_date DATE NOT NULL DEFAULT CURRENT_DATE;

-- Indexes
CREATE INDEX idx_chat_questions_match ON chat_questions(match_id);
CREATE INDEX idx_chat_questions_sender_date ON chat_questions(sender_id, match_id, question_date);
CREATE INDEX idx_message_reactions_message ON message_reactions(message_id);
CREATE INDEX idx_messages_not_deleted ON messages(match_id, created_at) WHERE deleted_at IS NULL;
```

**Step 2: Commit**

```bash
git add supabase/migrations/016_chat_enhancements.sql
git commit -m "feat: add chat enhancements migration 016 — questions, reactions, delete, voice"
```

---

### Task 10: Backend — Chat Questions Endpoints

**Files:**
- Create: `server/src/services/chat-question.service.ts`
- Create: `server/src/controllers/chat-question.controller.ts`
- Create: `server/src/validators/chat-question.validator.ts`
- Modify: `server/src/routes/chat.routes.ts`

**Step 1: chat-question.validator.ts**

```typescript
import Joi from "joi";

export const createChatQuestionSchema = Joi.object({
  question_text: Joi.string().min(3).max(200).required(),
  option_a: Joi.string().min(1).max(100).required(),
  option_b: Joi.string().min(1).max(100).required(),
  correct_option: Joi.string().valid("A", "B").required(),
  has_unmatch_risk: Joi.boolean().default(false),
});

export const answerChatQuestionSchema = Joi.object({
  selected_option: Joi.string().valid("A", "B").required(),
});
```

**Step 2: chat-question.service.ts**

```typescript
import { supabase } from "../config/supabase.js";
import { Errors } from "../utils/errors.js";
import { diamondService } from "./diamond.service.js";
import { matchingService } from "./matching.service.js";
import { NotificationService } from "./notification.service.js";

class ChatQuestionService {
  async createQuestion(
    matchId: string,
    senderId: string,
    data: {
      question_text: string;
      option_a: string;
      option_b: string;
      correct_option: "A" | "B";
      has_unmatch_risk: boolean;
    }
  ) {
    // Match erişim kontrolü
    await this.verifyMatchAccess(matchId, senderId);

    // Günlük limit kontrolü (max 2 soru/gün, max 1 unmatch riskli)
    const today = new Date().toISOString().split("T")[0];
    const { data: todayQuestions, error: countErr } = await supabase
      .from("chat_questions")
      .select("id, has_unmatch_risk")
      .eq("match_id", matchId)
      .eq("sender_id", senderId)
      .eq("question_date", today);

    if (countErr) throw Errors.SERVER_ERROR();

    const dailyCount = todayQuestions?.length ?? 0;
    if (dailyCount >= 2) {
      throw Errors.BAD_REQUEST("Günlük soru limitine ulaştın (max 2)");
    }

    if (data.has_unmatch_risk) {
      const riskCount = todayQuestions?.filter((q: any) => q.has_unmatch_risk).length ?? 0;
      if (riskCount >= 1) {
        throw Errors.BAD_REQUEST("Günlük riskli soru limitine ulaştın (max 1)");
      }
    }

    // Diamond maliyeti
    const cost = data.has_unmatch_risk ? 15 : 5;
    await diamondService.deductPurple(senderId, cost, "chat_question", matchId);

    // Soru oluştur
    const { data: question, error } = await supabase
      .from("chat_questions")
      .insert({
        match_id: matchId,
        sender_id: senderId,
        question_text: data.question_text,
        option_a: data.option_a,
        option_b: data.option_b,
        correct_option: data.correct_option,
        has_unmatch_risk: data.has_unmatch_risk,
        diamond_cost: cost,
        question_date: today,
      })
      .select()
      .single();

    if (error) throw Errors.SERVER_ERROR();

    // Karşı tarafa push
    const otherUserId = await this.getOtherUser(matchId, senderId);
    NotificationService.sendPush(otherUserId, "new_message", {}, `/matches/chat/${matchId}`).catch(() => {});

    return question;
  }

  async answerQuestion(questionId: string, userId: string, selectedOption: "A" | "B") {
    // Soruyu getir
    const { data: question, error } = await supabase
      .from("chat_questions")
      .select("*")
      .eq("id", questionId)
      .single();

    if (error || !question) throw Errors.NOT_FOUND("Soru bulunamadı");
    if (question.answered_option) throw Errors.BAD_REQUEST("Bu soru zaten cevaplanmış");
    if (question.sender_id === userId) throw Errors.BAD_REQUEST("Kendi sorunuzu cevaplayamazsınız");

    // Match erişim kontrolü
    await this.verifyMatchAccess(question.match_id, userId);

    const isCorrect = selectedOption === question.correct_option;

    // Cevabı kaydet
    const { error: updateErr } = await supabase
      .from("chat_questions")
      .update({
        answered_option: selectedOption,
        is_correct: isCorrect,
        answered_at: new Date().toISOString(),
      })
      .eq("id", questionId);

    if (updateErr) throw Errors.SERVER_ERROR();

    // Yanlış + unmatch riski varsa → unmatch
    if (!isCorrect && question.has_unmatch_risk) {
      await matchingService.unmatch(userId, question.match_id);
      return { is_correct: false, unmatched: true };
    }

    return { is_correct: isCorrect, unmatched: false };
  }

  private async verifyMatchAccess(matchId: string, userId: string) {
    const { data: match, error } = await supabase
      .from("matches")
      .select("user1_id, user2_id, is_active")
      .eq("id", matchId)
      .single();

    if (error || !match) throw Errors.NOT_FOUND("Match bulunamadı");
    if (!match.is_active) throw Errors.BAD_REQUEST("Match artık aktif değil");
    if (match.user1_id !== userId && match.user2_id !== userId) {
      throw Errors.FORBIDDEN();
    }
  }

  private async getOtherUser(matchId: string, userId: string): Promise<string> {
    const { data: match } = await supabase
      .from("matches")
      .select("user1_id, user2_id")
      .eq("id", matchId)
      .single();

    if (!match) throw Errors.NOT_FOUND("Match bulunamadı");
    return match.user1_id === userId ? match.user2_id : match.user1_id;
  }
}

export const chatQuestionService = new ChatQuestionService();
```

**Step 3: chat-question.controller.ts**

```typescript
import { Request, Response, NextFunction } from "express";
import { chatQuestionService } from "../services/chat-question.service.js";

export async function createChatQuestionHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.id;
    const { match_id } = req.params;
    const question = await chatQuestionService.createQuestion(match_id, userId, req.body);
    res.status(201).json(question);
  } catch (err) {
    next(err);
  }
}

export async function answerChatQuestionHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.id;
    const { id } = req.params;
    const result = await chatQuestionService.answerQuestion(id, userId, req.body.selected_option);
    res.json(result);
  } catch (err) {
    next(err);
  }
}
```

**Step 4: chat.routes.ts — yeni route'lar ekle**

Mevcut route dosyasına ekle:

```typescript
import { validate } from "../middleware/validate.js";
import { createChatQuestionSchema, answerChatQuestionSchema } from "../validators/chat-question.validator.js";
import { createChatQuestionHandler, answerChatQuestionHandler } from "../controllers/chat-question.controller.js";

// Mevcut route'lardan sonra:
router.post("/:match_id/questions", validate(createChatQuestionSchema), createChatQuestionHandler);
router.post("/questions/:id/answer", validate(answerChatQuestionSchema), answerChatQuestionHandler);
```

**Step 5: Commit**

```bash
git add server/src/services/chat-question.service.ts server/src/controllers/chat-question.controller.ts server/src/validators/chat-question.validator.ts server/src/routes/chat.routes.ts
git commit -m "feat(backend): add chat question system — create, answer, unmatch risk"
```

---

### Task 11: Backend — Message Reactions & Delete

**Files:**
- Modify: `server/src/services/chat.service.ts`
- Modify: `server/src/controllers/chat.controller.ts`
- Modify: `server/src/routes/chat.routes.ts`
- Modify: `server/src/validators/chat.validator.ts`

**Step 1: chat.validator.ts — yeni şemalar ekle**

```typescript
export const reactionSchema = Joi.object({
  emoji: Joi.string().min(1).max(10).required(),
});
```

**Step 2: chat.service.ts — yeni metodlar ekle**

Mevcut `ChatService` class'ına ekle:

```typescript
async deleteMessage(matchId: string, messageId: string, userId: string) {
  await this.verifyMatchAccess(matchId, userId);

  // Sadece kendi mesajını silebilir
  const { data: msg, error } = await supabase
    .from("messages")
    .select("sender_id")
    .eq("id", messageId)
    .eq("match_id", matchId)
    .single();

  if (error || !msg) throw Errors.NOT_FOUND("Mesaj bulunamadı");
  if (msg.sender_id !== userId) throw Errors.FORBIDDEN();

  const { error: delErr } = await supabase
    .from("messages")
    .update({ deleted_at: new Date().toISOString() })
    .eq("id", messageId);

  if (delErr) throw Errors.SERVER_ERROR();
}

async addReaction(matchId: string, messageId: string, userId: string, emoji: string) {
  await this.verifyMatchAccess(matchId, userId);

  const { error } = await supabase
    .from("message_reactions")
    .insert({ message_id: messageId, user_id: userId, emoji });

  if (error && error.code === "23505") {
    // Zaten var, kaldır (toggle)
    await supabase
      .from("message_reactions")
      .delete()
      .eq("message_id", messageId)
      .eq("user_id", userId)
      .eq("emoji", emoji);
    return { toggled: "removed" };
  }

  if (error) throw Errors.SERVER_ERROR();
  return { toggled: "added" };
}
```

Ayrıca `getMessages` metodunu güncelle — soft delete'li mesajları filtrele ve reaction'ları dahil et:

```typescript
// getMessages içindeki sorguyu güncelle:
const { data, error, count } = await supabase
  .from("messages")
  .select("*, reactions:message_reactions(emoji, user_id)", { count: "exact" })
  .eq("match_id", matchId)
  .is("deleted_at", null) // Soft delete filtresi
  .order("created_at", { ascending: false })
  .range(offset, offset + limit - 1);
```

**Step 3: chat.controller.ts — yeni handler'lar ekle**

```typescript
export async function deleteMessageHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.id;
    const { match_id, message_id } = req.params;
    await chatService.deleteMessage(match_id, message_id, userId);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

export async function addReactionHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.id;
    const { match_id, message_id } = req.params;
    const result = await chatService.addReaction(match_id, message_id, userId, req.body.emoji);
    res.json(result);
  } catch (err) {
    next(err);
  }
}
```

**Step 4: chat.routes.ts — yeni route'lar ekle**

```typescript
import { reactionSchema } from "../validators/chat.validator.js";
import { deleteMessageHandler, addReactionHandler } from "../controllers/chat.controller.js";

router.delete("/:match_id/messages/:message_id", deleteMessageHandler);
router.post("/:match_id/messages/:message_id/reactions", validate(reactionSchema), addReactionHandler);
```

**Step 5: Commit**

```bash
git add server/src/services/chat.service.ts server/src/controllers/chat.controller.ts server/src/routes/chat.routes.ts server/src/validators/chat.validator.ts
git commit -m "feat(backend): add message delete (soft) and reaction toggle endpoints"
```

---

### Task 12: Flutter Models — Chat Enhancements

**Files:**
- Create: `lib/data/models/chat_question_model.dart`
- Modify: `lib/data/models/message_model.dart`

**Step 1: chat_question_model.dart**

```dart
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_question_model.g.dart';

@JsonSerializable()
class ChatQuestionModel extends Equatable {
  final String id;
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'sender_id')
  final String senderId;
  @JsonKey(name: 'question_text')
  final String questionText;
  @JsonKey(name: 'option_a')
  final String optionA;
  @JsonKey(name: 'option_b')
  final String optionB;
  @JsonKey(name: 'has_unmatch_risk')
  final bool hasUnmatchRisk;
  @JsonKey(name: 'diamond_cost')
  final int diamondCost;
  @JsonKey(name: 'answered_option')
  final String? answeredOption;
  @JsonKey(name: 'is_correct')
  final bool? isCorrect;
  @JsonKey(name: 'answered_at')
  final String? answeredAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const ChatQuestionModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    this.hasUnmatchRisk = false,
    this.diamondCost = 5,
    this.answeredOption,
    this.isCorrect,
    this.answeredAt,
    required this.createdAt,
  });

  factory ChatQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatQuestionModelToJson(this);

  bool get isAnswered => answeredOption != null;

  @override
  List<Object?> get props => [id];
}

@JsonSerializable()
class ChatQuestionAnswerResponse extends Equatable {
  @JsonKey(name: 'is_correct')
  final bool isCorrect;
  final bool unmatched;

  const ChatQuestionAnswerResponse({
    required this.isCorrect,
    required this.unmatched,
  });

  factory ChatQuestionAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatQuestionAnswerResponseFromJson(json);

  @override
  List<Object?> get props => [isCorrect, unmatched];
}
```

**Step 2: message_model.dart — reaction ve delete alanları ekle**

MessageModel'e yeni alanlar ekle:

```dart
@JsonKey(name: 'deleted_at')
final String? deletedAt;
@JsonKey(name: 'audio_url')
final String? audioUrl;
@JsonKey(name: 'audio_duration_seconds')
final int? audioDurationSeconds;
final List<MessageReaction>? reactions;

bool get isDeleted => deletedAt != null;
bool get isAudio => audioUrl != null;
```

Yeni model ekle (aynı dosyada):

```dart
@JsonSerializable()
class MessageReaction extends Equatable {
  final String emoji;
  @JsonKey(name: 'user_id')
  final String userId;

  const MessageReaction({required this.emoji, required this.userId});

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionFromJson(json);

  @override
  List<Object?> get props => [emoji, userId];
}
```

**Step 3: build_runner çalıştır**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulov2 && dart run build_runner build --delete-conflicting-outputs
```

**Step 4: Commit**

```bash
git add lib/data/models/chat_question_model.dart lib/data/models/chat_question_model.g.dart lib/data/models/message_model.dart lib/data/models/message_model.g.dart
git commit -m "feat: add chat question model and message reaction/delete/audio fields"
```

---

### Task 13: Flutter — Chat Service & Repository Güncellemeleri

**Files:**
- Modify: `lib/core/network/services/chat_service.dart`
- Create: `lib/core/network/services/chat_question_service.dart`
- Modify: `lib/data/repositories/chat_repository.dart`
- Modify: `lib/data/repositories/interfaces.dart`
- Modify: `lib/providers/api_provider.dart`

**Step 1: chat_service.dart — yeni endpoint'ler ekle**

```dart
@DELETE('/chat/{matchId}/messages/{messageId}')
Future<void> deleteMessage(
  @Path('matchId') String matchId,
  @Path('messageId') String messageId,
);

@POST('/chat/{matchId}/messages/{messageId}/reactions')
Future<Map<String, dynamic>> addReaction(
  @Path('matchId') String matchId,
  @Path('messageId') String messageId,
  @Body() Map<String, dynamic> data,
);
```

**Step 2: chat_question_service.dart oluştur**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';

part 'chat_question_service.g.dart';

@RestApi()
abstract class ChatQuestionService {
  factory ChatQuestionService(Dio dio) = _ChatQuestionService;

  @POST('/chat/{matchId}/questions')
  Future<ChatQuestionModel> createQuestion(
    @Path('matchId') String matchId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/chat/questions/{questionId}/answer')
  Future<ChatQuestionAnswerResponse> answerQuestion(
    @Path('questionId') String questionId,
    @Body() Map<String, dynamic> data,
  );
}
```

**Step 3: chat_repository.dart — yeni metodlar ekle**

```dart
Future<Result<void>> deleteMessage(String matchId, String messageId) async {
  try {
    await _service.deleteMessage(matchId, messageId);
    return const Result.success(null);
  } on DioException catch (e) {
    return Result.failure(e.toAppFailure());
  }
}

Future<Result<Map<String, dynamic>>> addReaction(String matchId, String messageId, String emoji) async {
  try {
    final result = await _service.addReaction(matchId, messageId, {'emoji': emoji});
    return Result.success(result);
  } on DioException catch (e) {
    return Result.failure(e.toAppFailure());
  }
}

// Chat question metodları ayrı repository'de olacak
```

**Step 4: api_provider.dart — yeni provider'lar ekle**

```dart
final chatQuestionServiceProvider = Provider<ChatQuestionService>(
  (ref) => ChatQuestionService(ref.read(networkManagerProvider).dio),
);
```

**Step 5: build_runner çalıştır**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 6: Commit**

```bash
git add lib/core/network/services/chat_service.dart lib/core/network/services/chat_service.g.dart lib/core/network/services/chat_question_service.dart lib/core/network/services/chat_question_service.g.dart lib/data/repositories/chat_repository.dart lib/data/repositories/interfaces.dart lib/providers/api_provider.dart
git commit -m "feat: add chat question service, message delete/reaction API integration"
```

---

### Task 14: Flutter — Typing Indicator

**Files:**
- Create: `lib/features/chat/widgets/typing_indicator.dart`
- Modify: `lib/features/chat/screens/chat_screen.dart`

**Step 1: typing_indicator.dart oluştur**

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = i * 0.2;
                    final value = ((_controller.value + delay) % 1.0);
                    final opacity = (1 - (value - 0.5).abs() * 2).clamp(0.3, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: chat_screen.dart — typing indicator entegrasyonu**

State'e `_isOtherTyping` ekle. Supabase Realtime broadcast channel kullanarak typing bilgisi gönder/al:

```dart
bool _isOtherTyping = false;
Timer? _typingDebounce;
RealtimeChannel? _typingChannel;

// initState'e ekle:
void _subscribeTyping() {
  _typingChannel = Supabase.instance.client.channel('typing:${widget.matchId}');
  _typingChannel!.onBroadcast(
    event: 'typing',
    callback: (payload) {
      final senderId = payload['user_id'] as String?;
      if (senderId != null && senderId != _currentUserId) {
        setState(() => _isOtherTyping = true);
        _typingDebounce?.cancel();
        _typingDebounce = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isOtherTyping = false);
        });
      }
    },
  ).subscribe();
}

void _sendTypingEvent() {
  _typingChannel?.sendBroadcastMessage(
    event: 'typing',
    payload: {'user_id': _currentUserId},
  );
}

// dispose'a ekle:
_typingChannel?.unsubscribe();
_typingDebounce?.cancel();

// TextField onChanged'e ekle:
onChanged: (_) => _sendTypingEvent(),

// ListView'ın üstüne, mesaj listesinin en altına ekle:
if (_isOtherTyping) const TypingIndicator(),
```

**Step 3: Commit**

```bash
git add lib/features/chat/widgets/typing_indicator.dart lib/features/chat/screens/chat_screen.dart
git commit -m "feat(chat): add typing indicator with Supabase Realtime broadcast"
```

---

### Task 15: Flutter — Message Reactions UI

**Files:**
- Create: `lib/features/chat/widgets/reaction_picker.dart`
- Modify: `lib/features/chat/screens/chat_screen.dart`

**Step 1: reaction_picker.dart**

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/theme.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;

  static const reactions = ['❤️', '😂', '😮', '😢', '👍', '🔥'];

  const ReactionPicker({super.key, required this.onReactionSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

**Step 2: chat_screen.dart — long press ile reaction picker göster**

Mesaj balonlarına `GestureDetector(onLongPress)` ekle:

```dart
// Mesaj balonu oluşturma bölümünde:
GestureDetector(
  onLongPress: () => _showMessageOptions(context, message),
  child: /* mevcut mesaj balonu */,
)

void _showMessageOptions(BuildContext context, MessageModel message) {
  final isMine = message.senderId == _currentUserId;
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: ReactionPicker(
              onReactionSelected: (emoji) {
                Navigator.pop(ctx);
                _addReaction(message.id, emoji);
              },
            ),
          ),
          if (isMine)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Mesajı Sil'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(message.id);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
```

Mesaj balonunun altına reaction badge'lerini göster:

```dart
// Mesaj balonunun altında:
if (message.reactions != null && message.reactions!.isNotEmpty)
  Padding(
    padding: EdgeInsets.only(
      left: isMine ? 0 : 8,
      right: isMine ? 8 : 0,
      top: 2,
    ),
    child: Wrap(
      spacing: 4,
      children: _groupReactions(message.reactions!).entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceInput,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    ),
  ),
```

**Step 3: Commit**

```bash
git add lib/features/chat/widgets/reaction_picker.dart lib/features/chat/screens/chat_screen.dart
git commit -m "feat(chat): add message reactions with long-press picker and badge display"
```

---

### Task 16: Flutter — Chat Question Card

**Files:**
- Create: `lib/features/chat/widgets/chat_question_card.dart`
- Create: `lib/features/chat/sheets/create_question_sheet.dart`
- Modify: `lib/features/chat/screens/chat_screen.dart`

**Step 1: chat_question_card.dart — soru kartı widget**

```dart
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/theme.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';

class ChatQuestionCard extends StatelessWidget {
  final ChatQuestionModel question;
  final bool isMyQuestion;
  final Function(String option)? onAnswer;

  const ChatQuestionCard({
    super.key,
    required this.question,
    required this.isMyQuestion,
    this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = question.isAnswered;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: question.hasUnmatchRisk ? AppColors.error.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk badge
          if (question.hasUnmatchRisk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Bu soru riskli!',
                    style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Soru metni
          Text(
            question.questionText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          // Şıklar
          if (!isAnswered && !isMyQuestion) ...[
            _OptionButton(
              label: 'A',
              text: question.optionA,
              onTap: () => onAnswer?.call('A'),
            ),
            const SizedBox(height: 8),
            _OptionButton(
              label: 'B',
              text: question.optionB,
              onTap: () => onAnswer?.call('B'),
            ),
          ] else if (isAnswered) ...[
            _AnsweredOption(
              label: 'A',
              text: question.optionA,
              isSelected: question.answeredOption == 'A',
              isCorrect: question.answeredOption == 'A' ? question.isCorrect! : null,
            ),
            const SizedBox(height: 8),
            _AnsweredOption(
              label: 'B',
              text: question.optionB,
              isSelected: question.answeredOption == 'B',
              isCorrect: question.answeredOption == 'B' ? question.isCorrect! : null,
            ),
            if (!question.isCorrect! && question.hasUnmatchRisk)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Unmatch gerçekleşti',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
          ] else ...[
            // Benim sorum, henüz cevaplanmamış
            Text('A: ${question.optionA}', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('B: ${question.optionB}', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Cevap bekleniyor...', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final String text;
  final VoidCallback? onTap;

  const _OptionButton({required this.label, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceInput,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('$label. $text', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      ),
    );
  }
}

class _AnsweredOption extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool? isCorrect;

  const _AnsweredOption({
    required this.label,
    required this.text,
    required this.isSelected,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = !isSelected
        ? AppColors.surfaceInput
        : isCorrect == true
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.15);

    final borderColor = !isSelected
        ? AppColors.border
        : isCorrect == true
            ? AppColors.success
            : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text('$label. $text', style: TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          if (isSelected && isCorrect != null)
            Icon(
              isCorrect! ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: isCorrect! ? AppColors.success : AppColors.error,
            ),
        ],
      ),
    );
  }
}
```

**Step 2: create_question_sheet.dart — soru oluşturma bottom sheet**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/theme.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class CreateQuestionSheet extends ConsumerStatefulWidget {
  final String matchId;
  final Function(Map<String, dynamic> data) onSubmit;

  const CreateQuestionSheet({
    super.key,
    required this.matchId,
    required this.onSubmit,
  });

  @override
  ConsumerState<CreateQuestionSheet> createState() => _CreateQuestionSheetState();
}

class _CreateQuestionSheetState extends ConsumerState<CreateQuestionSheet> {
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  String _correctOption = 'A';
  bool _hasUnmatchRisk = false;
  bool _isLoading = false;

  bool get _isValid =>
      _questionController.text.trim().length >= 3 &&
      _optionAController.text.trim().isNotEmpty &&
      _optionBController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cost = _hasUnmatchRisk ? 15 : 5;

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.help_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Soru Gönder', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 16),

            // Soru metni
            TextField(
              controller: _questionController,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Sorun',
                hintText: 'Ör: Tatilde plaj mı dağ mı?',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Şık A
            TextField(
              controller: _optionAController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'A şıkkı',
                suffixIcon: _correctOption == 'A'
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : IconButton(
                        icon: const Icon(Icons.circle_outlined),
                        onPressed: () => setState(() => _correctOption = 'A'),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Şık B
            TextField(
              controller: _optionBController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'B şıkkı',
                suffixIcon: _correctOption == 'B'
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : IconButton(
                        icon: const Icon(Icons.circle_outlined),
                        onPressed: () => setState(() => _correctOption = 'B'),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              'Doğru olmasını istediğin şıkkı ✓ ile işaretle',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),

            // Unmatch riski toggle
            SwitchListTile(
              title: const Text('Yanlış cevaplarsa unmatch olsun mu?'),
              subtitle: Text(
                _hasUnmatchRisk ? '⚠️ Riskli soru — 15 💎' : 'Normal soru — 5 💎',
                style: TextStyle(
                  color: _hasUnmatchRisk ? AppColors.error : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              value: _hasUnmatchRisk,
              onChanged: (v) => setState(() => _hasUnmatchRisk = v),
              activeColor: AppColors.error,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Gönder butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_isValid || _isLoading ? null : _submit,
                child: _isLoading
                    ? const AppLoadingWidget.small()
                    : Text('Gönder ($cost 💎)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await widget.onSubmit({
        'question_text': _questionController.text.trim(),
        'option_a': _optionAController.text.trim(),
        'option_b': _optionBController.text.trim(),
        'correct_option': _correctOption,
        'has_unmatch_risk': _hasUnmatchRisk,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

**Step 3: chat_screen.dart — soru kartı ve oluşturma butonu entegrasyonu**

Input alanının yanına soru gönder butonu ekle:

```dart
// Mesaj input satırına "?" butonu ekle:
IconButton(
  icon: const Icon(Icons.help_outline, color: AppColors.primary),
  onPressed: () => _showCreateQuestionSheet(),
),
```

Chat question oluşturma ve cevaplama metodları:

```dart
void _showCreateQuestionSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => CreateQuestionSheet(
      matchId: widget.matchId,
      onSubmit: (data) async {
        // API call ile soru gönder
        // Realtime subscription ile karşı tarafa iletilecek
      },
    ),
  );
}
```

**Step 4: Commit**

```bash
git add lib/features/chat/widgets/chat_question_card.dart lib/features/chat/sheets/create_question_sheet.dart lib/features/chat/screens/chat_screen.dart
git commit -m "feat(chat): add chat question card widget and create question sheet"
```

---

### Task 17: Flutter — Unmatch from Chat

**Files:**
- Modify: `lib/features/chat/screens/chat_screen.dart`

**Step 1: Chat AppBar'a unmatch menüsü ekle**

```dart
// AppScaffold'un actions'ına ekle:
actions: [
  PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) {
      if (value == 'unmatch') _confirmUnmatch();
    },
    itemBuilder: (ctx) => [
      const PopupMenuItem(
        value: 'unmatch',
        child: Row(
          children: [
            Icon(Icons.heart_broken, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Unmatch'),
          ],
        ),
      ),
    ],
  ),
],
```

Unmatch onay dialogu:

```dart
Future<void> _confirmUnmatch() async {
  final confirmed = await ref.read(navigationServiceProvider).showAppDialog<bool>(
    ConfirmDialog(
      title: 'Unmatch',
      message: 'Bu kişiyle eşleşmeyi kaldırmak istediğine emin misin? Bu işlem geri alınamaz.',
      confirmText: 'Unmatch',
      cancelText: 'İptal',
      isDestructive: true,
    ),
  );

  if (confirmed == true && mounted) {
    await ref.read(matchListProvider.notifier).unmatch(widget.matchId);
    ref.read(navigationServiceProvider).pop();
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/chat/screens/chat_screen.dart
git commit -m "feat(chat): add unmatch option in chat menu with confirm dialog"
```

---

### Task 18: Online/Offline Status

**Files:**
- Modify: `lib/features/chat/screens/chat_screen.dart` (header'da online durumu)
- Modify: `lib/data/models/match_model.dart` (isOnline zaten var)

**Step 1: chat_screen.dart — AppBar'da online durumu göster**

AppBar title'ını kullanıcı adı + online durumu ile güncelle:

```dart
// AppBar title bölümünde:
title: Row(
  children: [
    // Online dot
    Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppColors.success : AppColors.textHint,
      ),
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(userName, style: Theme.of(context).textTheme.titleMedium),
        Text(
          isOnline ? 'Online' : 'Son görülme: $lastSeenText',
          style: TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    ),
  ],
),
```

> **NOT:** `isOnline` ve `lastSeen` bilgisi match model'den gelir. Chat ekranına match bilgisini extra param olarak geçirmek gerekebilir.

**Step 2: Commit**

```bash
git add lib/features/chat/screens/chat_screen.dart
git commit -m "feat(chat): show online/offline status in chat header"
```

---

## Phase 5: Son Dokunuşlar

### Task 19: Analytics Events — Yeni Eventler

**Files:**
- Modify: `lib/core/services/analytics_manager.dart`

**Step 1: Yeni event'ler ekle**

Quiz ve chat yeni eventleri:

```dart
// Quiz events (mevcut olanları güncelle):
// quiz_answer_confirm — seç+onayla ile cevaplandı
// quiz_exit_attempt — çıkış denemesi
// quiz_exit_confirm — çıkış onaylandı
// quiz_timer_warning — son 10sn
// quiz_timer_critical — son 5sn

// Match celebration events:
// match_celebration_shown — kutlama ekranı gösterildi
// match_celebration_start_chat — "send message" tıklandı
// match_celebration_go_back — "go back" tıklandı

// Chat events:
// chat_reaction_add — reaction eklendi
// chat_reaction_remove — reaction kaldırıldı
// chat_message_delete — mesaj silindi
// chat_question_create — soru oluşturuldu
// chat_question_answer — soru cevaplanındı
// chat_question_unmatch — soru sonucu unmatch
// chat_typing_start — yazıyor
```

**Step 2: Commit**

```bash
git add lib/core/services/analytics_manager.dart
git commit -m "feat(analytics): add quiz UX, match celebration, and chat enhancement events"
```

---

### Task 20: Memory Güncellemesi

**Files:**
- Modify: `/Users/berkantcalikusu/.claude/projects/-Users-berkantcalikusu-IdeaProjects-qulov2/memory/MEMORY.md`
- Modify: `/Users/berkantcalikusu/.claude/projects/-Users-berkantcalikusu-IdeaProjects-qulov2/memory/completed-features.md`

**Step 1: MEMORY.md güncelle**

DB Migrations bölümünü güncelle:
```markdown
## DB Migrations
- Son migration: **016** (chat_enhancements)
- Sonraki migration numarası: **017**
- Çalıştırılmamış: 014 (referral_system), 015 (quiz_session_total_questions), 016 (chat_enhancements)
```

**Step 2: completed-features.md güncelle**

Yeni feature'ları ekle:
```markdown
## Quiz → Match → Chat Flow (2026-03-09)
- Quiz UX: Seç+onayla cevap mekaniği, timer gerilim katmanları (pulse/shake), çıkış koruması
- Answer feedback: Doğru/yanlış animasyonları (yeşil checkmark, kırmızı X + doğru cevap)
- Discover → Quiz: Zoom-in geçiş animasyonu
- Match kutlama: Badge odaklı tam ekran (FLAWLESS, SPEED SOLVER, POWER MASTER, DETERMINED)
- Push notification: quiz_started kaldırıldı, match push badge bilgisiyle zenginleştirildi
- Chat typing indicator: Supabase Realtime broadcast
- Chat reactions: Long-press emoji picker (❤️😂😮😢👍🔥)
- Chat message delete: Soft delete + "Bu mesaj silindi" placeholder
- Chat unmatch: Menüden onaylı unmatch
- Chat question system: 2 şıklı custom soru, unmatch riski toggle, risk bazlı fiyat (5/15 purple), günde max 2 soru
- Online/offline durumu: Chat header'da yeşil/gri nokta
```

**Step 3: Commit**

```bash
# Bu adımda git commit yok — memory dosyaları repo dışı
```

---

## Özet: Task Sıralaması ve Bağımlılıklar

```
Phase 1 (Blocker):     Task 1 → Task 2 (paralel olabilir)
Phase 2 (Quiz UX):     Task 3 → Task 4 → Task 5 → Task 6 → Task 7 (sıralı)
Phase 3 (Match):       Task 8 (Phase 2'ye bağımlı)
Phase 4 (Chat):        Task 9 → Task 10 → Task 11 → Task 12 → Task 13 → Task 14 → Task 15 → Task 16 → Task 17 → Task 18
Phase 5 (Polish):      Task 19 → Task 20 (en son)
```

**Paralel çalışabilenler:**
- Phase 1 (Task 1-2) tamamen bağımsız
- Phase 2 (Task 3-7) kendi içinde sıralı, ama Phase 4 (Task 9-11 backend) ile paralel yapılabilir
- Phase 3 (Task 8) Phase 2'ye bağımlı
- Phase 4'te backend (Task 9-11) ve Flutter (Task 12-18) kısmen paralel yapılabilir

**Tahmini commit sayısı:** ~20 commit
