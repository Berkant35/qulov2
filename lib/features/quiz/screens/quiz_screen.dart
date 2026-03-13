import 'dart:ui';

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
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
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
  bool _isSheetOpen = false;
  bool _showCelebration = false;
  bool _celebrationMatched = false;
  String _celebrationBadge = 'none';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      ref.read(exchangeProvider.notifier).fetchAll();
      await ref.read(quizProvider.notifier).startSession(widget.targetId);
      if (!mounted) return;
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

    result.when(
      success: (data) {
        setState(() => _isSubmitting = false);
        _handleAnswerResponse(data);
      },
      failure: (_) {
        setState(() => _isSubmitting = false);
        _timerKey.currentState?.resume();
      },
    );
  }

  // ── Power kullanımı (cevap göndermeden) ──────────────────────
  Future<void> _usePower(String power) async {
    if (_isSubmitting) return;

    // SKIP/SKIP_ALL gibi sonlandırıcı power'lar için timer'ı durdur
    final isTerminating = power == 'SKIP' || power == 'SKIP_ALL';
    if (isTerminating) {
      _timerKey.currentState?.pause();
    }

    setState(() => _isSubmitting = true);

    final result = await ref.read(quizProvider.notifier).answer(
          null,
          powerUsed: power,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (data) {
        // Power kullanıldı — envanter sayısını güncelle
        ref.read(exchangeProvider.notifier).fetchAll();

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
      failure: (f) {
        // Hata durumunda timer'ı geri başlat
        if (isTerminating) {
          _timerKey.currentState?.resume();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message ?? context.tr('quiz_power_failed')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  // ── Cevap response handler ──────────────────────────────────
  void _handleAnswerResponse(QuizAnswerResponse data) {
    if (data.awaitingAnswer == true) return;

    final isCorrect = data.isCorrect == true;
    if (isCorrect) _totalCorrect++;

    // Completion analytics
    if (data.sessionStatus == 'COMPLETED') {
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

  // ── Feedback tamamlandı (doğru cevap sonrası otomatik) ──────
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

  // ── Rescue — kullanıcı SKIP veya SKIP_ALL ile kurtulma ──────
  Future<void> _onRescue(String powerType) async {
    setState(() => _isSubmitting = true);

    final result = await ref.read(quizProvider.notifier).rescue(powerType: powerType);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (data) {
        _powersUsed++;
        _totalCorrect++; // yanlış cevap override edildi
        ref.read(exchangeProvider.notifier).fetchAll();
        _resetQuestionState();

        if (data.sessionStatus == 'COMPLETED') {
          _showGamifiedResult(matched: true, badge: data.badge ?? 'none');
        } else {
          ref.read(quizProvider.notifier).fetchCurrentQuestion();
          _startQuestionTimer();
        }
      },
      failure: (f) {
        // Rescue başarısız — kullanıcıya hata göster, quiz'i fail yapma
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message ?? context.tr('quiz_rescue_failed')),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
        title: context.tr('quiz_exit_title'),
        message: context.tr('quiz_exit_message'),
        confirmText: context.tr('quiz_exit_confirm'),
        cancelText: context.tr('quiz_exit_cancel'),
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

  int _getPowerCost(String powerName) {
    final rates = ref.read(exchangeProvider).rates;
    if (rates != null) {
      final power = rates.powers.where((p) => p.name == powerName).firstOrNull;
      if (power != null) return power.purpleCost;
    }
    return 20;
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
                            child: SafeTapButton(
                              onTap: _isSubmitting ? null : () => _submitAnswer(),
                              builder: (context, isLoading, onTap) => ElevatedButton(
                                onPressed: onTap,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                  backgroundColor: AppColors.primary,
                                ),
                                child: (isLoading || _isSubmitting)
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
                          ),
                        const Spacer(),
                        PowerBar(
                          sessionId: quiz.sessionId!,
                          hasHint: question.hasHint,
                          onPowerUsed: _usePower,
                          onSheetOpening: () {
                            _timerKey.currentState?.pause();
                            setState(() => _isSheetOpen = true);
                          },
                          onSheetClosed: () {
                            _timerKey.currentState?.resume();
                            setState(() => _isSheetOpen = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isSheetOpen)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  if (_showFeedback)
                    AnswerFeedbackOverlay(
                      isCorrect: _feedbackCorrect,
                      onComplete: _onFeedbackComplete,
                      canRescue: _canRescue,
                      skipOption: RescuePowerOption(
                        type: PowerType.skip,
                        inventoryCount: ref.read(exchangeProvider).getCount('SKIP'),
                        diamondCost: _getPowerCost('SKIP'),
                      ),
                      skipAllOption: RescuePowerOption(
                        type: PowerType.skipAll,
                        inventoryCount: ref.read(exchangeProvider).getCount('SKIP_ALL'),
                        diamondCost: _getPowerCost('SKIP_ALL'),
                      ),
                      onRescue: _onRescue,
                      onDeclineRescue: _onDeclineRescue,
                    ),
                ],
              ),
      ),
    );
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
