import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';

/// Soru cevaplama akisi — sik secimi, gonderim, geri bildirim, timeout.
mixin QuizAnswerMixin on QuizScreenStateMixin {
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

    final questionIndex =
        ref.read(quizProvider).currentQuestion?.questionNumber ?? 0;

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizAnswerConfirm,
      params: {
        AnalyticsEvents.paramAnswerIndex: selectedAnswerIndex!,
        AnalyticsEvents.paramQuestionIndex: questionIndex,
      },
    );

    setState(() => isSubmitting = true);

    stopwatch.stop();
    final timeSpent = stopwatch.elapsedMilliseconds ~/ 1000;
    totalTimeSpent += timeSpent;

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
      logQuizComplete(matched: true);
    }

    if (data.canRescue == true) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.quizRescueShown);
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
    resetQuestionState();

    if (status == 'COMPLETED') {
      showGamifiedResult(matched: true, badge: badge ?? 'none');
    } else {
      ref.read(quizProvider.notifier).fetchCurrentQuestion();
      startQuestionTimer();
    }
  }

  Future<void> onTimeout() async {
    stopwatch.stop();
    HapticManager.instance.warning();
    await ref.read(quizProvider.notifier).fail();

    if (!mounted) return;
    logQuizComplete(matched: false);
    showGamifiedResult(matched: false, badge: 'none');
  }
}
