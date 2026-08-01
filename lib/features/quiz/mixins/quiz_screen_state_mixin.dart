import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

/// Quiz ekraninin paylasilan durumu ve oturum yasam dongusu.
///
/// Domain mixin'leri (`QuizAnswerMixin`, `QuizPowerMixin`, `QuizFlowMixin`) bunun
/// uzerine biner. Boylece her dosya tek bir konuyla ilgileniyor — eski tek parca
/// mixin 488 satira cikmisti (limit 300).
mixin QuizScreenStateMixin on ConsumerState<QuizScreen> {
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
      final result =
          await ref.read(quizProvider.notifier).startSession(widget.targetId);
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
              AnalyticsEvents.paramErrorCode:
                  f is ServerFailure ? f.code : 'unknown',
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

  /// Bottom sheet (paywall) acilirken timer'i durdur, kapaninca devam ettir.
  void onSheetOpening() {
    timerKey.currentState?.pause();
    if (mounted) setState(() => isSheetOpen = true);
  }

  void onSheetClosed() {
    timerKey.currentState?.resume();
    if (mounted) setState(() => isSheetOpen = false);
  }

  void handleSessionTransition(String? status, String? badge) {
    if (status == 'COMPLETED') {
      logQuizComplete(matched: true);
      showGamifiedResult(matched: true, badge: badge ?? 'none');
    } else if (status == 'FAILED') {
      logQuizComplete(matched: false);
      showGamifiedResult(matched: false, badge: 'none');
    } else {
      resetQuestionState();
      ref.read(quizProvider.notifier).fetchCurrentQuestion();
      startQuestionTimer();
    }
  }

  /// Oturum kapanis olcumu. `quiz_complete` daha once yalnizca duz cevap yolunda
  /// atesleniyordu; rescue ve guc yollari sessizdi (Faz 1 backlog'u).
  void logQuizComplete({required bool matched}) {
    if (sessionStopwatch.isRunning) sessionStopwatch.stop();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizComplete,
      params: {
        AnalyticsEvents.paramScore: totalCorrect,
        AnalyticsEvents.paramTotalDurationMs:
            sessionStopwatch.elapsedMilliseconds,
        AnalyticsEvents.paramMatched: matched,
      },
    );
    FunnelEvents.logAuthedOnce(
      AnalyticsEvents.flagFirstQuizComplete,
      AnalyticsEvents.firstQuizComplete,
      params: {AnalyticsEvents.paramMatched: matched},
    );
  }

  void resetQuestionState() {
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

  void showGamifiedResult({required bool matched, required String badge}) {
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
