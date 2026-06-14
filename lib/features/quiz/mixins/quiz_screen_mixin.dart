import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/app_review_manager.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

mixin QuizScreenMixin on ConsumerState<QuizScreen> {
  final timerKey = GlobalKey<QuizTimerState>();
  final stopwatch = Stopwatch();
  final sessionStopwatch = Stopwatch();
  int totalTimeSpent = 0;
  int totalCorrect = 0;
  int powersUsed = 0;
  int? oracleSuggestedIndex;
  int? selectedAnswerIndex;
  bool isSubmitting = false;
  bool showFeedback = false;
  bool feedbackCorrect = false;
  bool canRescue = false;
  String? pendingSessionStatus;
  String? pendingBadge;
  List<int> removedIndices = [];
  String? hintText;
  bool isSheetOpen = false;
  bool showCelebration = false;
  bool celebrationMatched = false;
  String celebrationBadge = 'none';

  void initMixin() {
    Future.microtask(() async {
      if (!mounted) return;
      ref.read(quizProvider.notifier).reset();
      ref.read(exchangeProvider.notifier).fetchAll();
      final result = await ref.read(quizProvider.notifier).startSession(widget.targetId);
      if (!mounted) return;
      result.when(
        success: (_) {
          startQuestionTimer();
          sessionStopwatch.start();
          AnalyticsManager.instance.logEvent(
            AnalyticsEvents.quizStart,
            params: {AnalyticsEvents.paramPartnerId: widget.targetId},
          );
        },
        failure: (f) {
          AnalyticsManager.instance.logEvent(
            AnalyticsEvents.quizStartFailed,
            params: {
              AnalyticsEvents.paramPartnerId: widget.targetId,
              AnalyticsEvents.paramErrorCode: f is ServerFailure ? f.code : 'unknown',
            },
          );
        },
      );
    });
  }

  void disposeMixin() {
    stopwatch.stop();
  }

  void startQuestionTimer() {
    stopwatch.reset();
    stopwatch.start();
  }

  void selectAnswer(int index) {
    final wasSelected = selectedAnswerIndex == index;
    setState(() {
      selectedAnswerIndex = wasSelected ? null : index;
    });
    if (!wasSelected) {
      HapticManager.instance.selection();
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

  Future<void> submitAnswer() async {
    if (selectedAnswerIndex == null || isSubmitting) return;
    timerKey.currentState?.pause();

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizAnswerConfirm,
      params: {
        AnalyticsEvents.paramAnswerIndex: selectedAnswerIndex!,
        AnalyticsEvents.paramQuestionIndex:
            ref.read(quizProvider).currentQuestion?.questionNumber ?? 0,
      },
    );

    setState(() => isSubmitting = true);

    stopwatch.stop();
    final timeSpent = stopwatch.elapsedMilliseconds ~/ 1000;
    totalTimeSpent += timeSpent;

    final questionIndex = ref.read(quizProvider).currentQuestion?.questionNumber ?? 0;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizAnswer,
      params: {
        AnalyticsEvents.paramQuestionIndex: questionIndex,
        AnalyticsEvents.paramDurationMs: stopwatch.elapsedMilliseconds,
      },
    );

    final result = await ref.read(quizProvider.notifier).answer(
          selectedAnswerIndex!,
          timeSpent: timeSpent,
        );

    if (!mounted) return;

    result.when(
      success: (data) {
        setState(() => isSubmitting = false);
        _handleAnswerResponse(data);
      },
      failure: (_) {
        setState(() => isSubmitting = false);
        timerKey.currentState?.resume();
      },
    );
  }

  Future<void> usePower(String power) async {
    if (isSubmitting) return;

    final isTerminating = power == 'SKIP' || power == 'SKIP_ALL';
    if (isTerminating) timerKey.currentState?.pause();

    setState(() => isSubmitting = true);

    final result = await ref.read(quizProvider.notifier).answer(
          null,
          powerUsed: power,
        );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    result.when(
      success: (data) {
        ref.read(exchangeProvider.notifier).fetchAll();

        if (data.awaitingAnswer == true) {
          powersUsed++;
          final powerResult = data.powerResult;
          if (powerResult != null) {
            setState(() {
              if (powerResult.containsKey('suggested_answer_index')) {
                oracleSuggestedIndex = powerResult['suggested_answer_index'] as int?;
              }
              if (powerResult.containsKey('removed_indices')) {
                removedIndices = (powerResult['removed_indices'] as List).cast<int>();
              }
              if (powerResult.containsKey('extra_seconds')) {
                final extra = powerResult['extra_seconds'] as int;
                timerKey.currentState?.addSeconds(extra);
              }
              if (powerResult.containsKey('hint_text')) {
                hintText = powerResult['hint_text'] as String?;
              }
            });
          }
        } else {
          powersUsed++;
          if (data.isCorrect == true) totalCorrect++;
          _handleSessionTransition(data.sessionStatus, data.badge);
        }
      },
      failure: (f) {
        if (isTerminating) timerKey.currentState?.resume();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(f.message ?? context.tr('quiz_power_failed')),
              backgroundColor: context.appColors.error,
            ),
          );
        }
      },
    );
  }

  void _handleAnswerResponse(QuizAnswerResponse data) {
    if (data.awaitingAnswer == true) return;

    final isCorrect = data.isCorrect == true;
    if (isCorrect) {
      totalCorrect++;
      HapticManager.instance.success();
    } else {
      HapticManager.instance.error();
    }

    if (data.sessionStatus == 'COMPLETED') {
      sessionStopwatch.stop();
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.quizComplete,
        params: {
          AnalyticsEvents.paramScore: totalCorrect,
          AnalyticsEvents.paramTotalDurationMs: sessionStopwatch.elapsedMilliseconds,
        },
      );
    }

    setState(() {
      feedbackCorrect = isCorrect;
      canRescue = data.canRescue == true;
      pendingSessionStatus = isCorrect ? data.sessionStatus : null;
      pendingBadge = data.badge;
      showFeedback = true;
    });
  }

  void onFeedbackComplete() {
    if (!mounted) return;
    final status = pendingSessionStatus;
    final badge = pendingBadge;
    _resetQuestionState();

    if (status == 'COMPLETED') {
      _showGamifiedResult(matched: true, badge: badge ?? 'none');
    } else {
      ref.read(quizProvider.notifier).fetchCurrentQuestion();
      startQuestionTimer();
    }
  }

  Future<void> onRescue(String powerType) async {
    setState(() => isSubmitting = true);

    final result = await ref.read(quizProvider.notifier).rescue(powerType: powerType);

    if (!mounted) return;
    setState(() => isSubmitting = false);

    result.when(
      success: (data) {
        powersUsed++;
        totalCorrect++;
        ref.read(exchangeProvider.notifier).fetchAll();
        _resetQuestionState();

        if (data.sessionStatus == 'COMPLETED') {
          _showGamifiedResult(matched: true, badge: data.badge ?? 'none');
        } else {
          ref.read(quizProvider.notifier).fetchCurrentQuestion();
          startQuestionTimer();
        }
      },
      failure: (f) {
        if (!mounted) return;
        // Rescue başarısız — overlay'i kapat ve session'ı sonlandır.
        // Aksi takdirde kullanıcı boş soruda stuck kalır (timer paused, decline butonu yok).
        _resetQuestionState();
        _handleRescueFailure(f);
      },
    );
  }

  Future<void> _handleRescueFailure(AppFailure f) async {
    if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
      await PaywallBottomSheetContent.show(ref, trigger: 'quiz_rescue');
    } else if (f is ServerFailure && f.code == 'DIAMOND_COOLDOWN') {
      // 24h social-signup cooldown — subscription bypass etmez; mesaj göster.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message ?? context.tr('quiz_rescue_failed')),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message ?? context.tr('quiz_rescue_failed')),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }

    if (!mounted) return;
    // Session'ı FAILED olarak kapat → kullanıcı result ekranı görsün, soruda stuck kalmasın.
    await ref.read(quizProvider.notifier).fail();
    if (!mounted) return;
    sessionStopwatch.stop();
    _showGamifiedResult(matched: false, badge: 'none');
  }

  Future<void> onDeclineRescue() async {
    await ref.read(quizProvider.notifier).fail();

    if (!mounted) return;
    _resetQuestionState();

    sessionStopwatch.stop();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizComplete,
      params: {
        AnalyticsEvents.paramScore: totalCorrect,
        AnalyticsEvents.paramTotalDurationMs: sessionStopwatch.elapsedMilliseconds,
      },
    );

    _showGamifiedResult(matched: false, badge: 'none');
  }

  Future<void> onTimeout() async {
    stopwatch.stop();
    HapticManager.instance.warning();
    await ref.read(quizProvider.notifier).fail();

    if (!mounted) return;
    sessionStopwatch.stop();

    _showGamifiedResult(matched: false, badge: 'none');
  }

  Future<void> confirmExit() async {
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

  int getPowerCost(String powerName) {
    final rates = ref.read(exchangeProvider).rates;
    if (rates != null) {
      final power = rates.powers.where((p) => p.name == powerName).firstOrNull;
      if (power != null) return power.purpleCost;
    }
    return 0;
  }

  void onStartChat() {
    ref.invalidate(matchListProvider);
    ref.read(navigationServiceProvider).go(RouteNames.matches);
    AppReviewManager.instance.tryShowReview(trigger: 'match_celebration');
  }

  void onGoBack() {
    ref.read(navigationServiceProvider).go(RouteNames.discover);
    AppReviewManager.instance.tryShowReview(trigger: 'match_celebration');
  }

  void _handleSessionTransition(String? status, String? badge) {
    if (status == 'COMPLETED') {
      _showGamifiedResult(matched: true, badge: badge ?? 'none');
    } else if (status == 'FAILED') {
      _showGamifiedResult(matched: false, badge: 'none');
    } else {
      _resetQuestionState();
      ref.read(quizProvider.notifier).fetchCurrentQuestion();
      startQuestionTimer();
    }
  }

  void _resetQuestionState() {
    setState(() {
      showFeedback = false;
      canRescue = false;
      pendingSessionStatus = null;
      pendingBadge = null;
      oracleSuggestedIndex = null;
      selectedAnswerIndex = null;
      removedIndices = [];
      hintText = null;
    });
  }

  void _showGamifiedResult({required bool matched, required String badge}) {
    stopwatch.stop();
    if (matched) {
      HapticManager.instance.success();
    }
    setState(() {
      showCelebration = true;
      celebrationMatched = matched;
      celebrationBadge = badge;
    });
  }
}
