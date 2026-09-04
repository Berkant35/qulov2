import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/compact_diamond_balance.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/features/quiz/quiz_power_rules.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_answer_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_flow_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_power_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_feedback_overlay.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_error_view.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_question_content.dart';
import 'package:qulo_v2/features/quiz/screens/match_celebration_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String targetId;
  final String? targetPhotoUrl;
  const QuizScreen({super.key, required this.targetId, this.targetPhotoUrl});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with QuizScreenStateMixin, QuizAnswerMixin, QuizPowerMixin, QuizFlowMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final question = quiz.currentQuestion;

    if (showCelebration) {
      final myPhotos = ref.read(userProvider).valueOrNull?.photos;
      final myPhoto = myPhotos?.isNotEmpty == true ? myPhotos!.first : null;
      return MatchCelebrationScreen(
        matched: celebrationMatched,
        totalCorrect: totalCorrect,
        totalQuestions: quiz.totalQuestions,
        totalTimeSpent: totalTimeSpent,
        powersUsed: powersUsed,
        performanceBadge: celebrationBadge,
        myPhotoUrl: myPhoto,
        targetPhotoUrl: widget.targetPhotoUrl,
        onStartChat: celebrationMatched ? onStartChat : null,
        onGoBack: onGoBack,
      );
    }

    if (quiz.failure != null) {
      return QuizErrorView(failure: quiz.failure!, onGoBack: onGoBack);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await confirmExit();
      },
      child: AppScaffold(
        title: question != null
            ? '${question.questionNumber}/${question.totalQuestions}'
            : '',
        leading: IconButton(
          icon: QIcon(QIcons.icX, size: 24),
          onPressed: confirmExit,
        ),
        actions: const [CompactDiamondBalance()],
        padding: EdgeInsets.zero,
        isLoading: question == null,
        body: question == null
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  QuizQuestionContent(
                    question: question,
                    timerKey: timerKey,
                    sessionId: quiz.sessionId!,
                    selectedAnswerIndex: selectedAnswerIndex,
                    oracleSuggestedIndex: oracleSuggestedIndex,
                    removedIndices: removedIndices,
                    hintText: hintText,
                    isSubmitting: isSubmitting,
                    onTimeout: onTimeout,
                    onSelectAnswer: selectAnswer,
                    onSubmitAnswer: submitAnswer,
                    onPowerUsed: usePower,
                  ),
                  if (isSheetOpen)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  if (showFeedback)
                    AnswerFeedbackOverlay(
                      isCorrect: feedbackCorrect,
                      onComplete: onFeedbackComplete,
                      canRescue: canRescue,
                      skipOption: RescuePowerOption(
                        type: PowerType.skip,
                        inventoryCount: ref.read(exchangeProvider).getCount('SKIP'),
                        diamondCost: quiz.purpleCostOf('SKIP'),
                      ),
                      // SKIP_ALL sadece kalan sorulari tek tek gecmekten UCUZ ise
                      // teklif edilir — 2 soruluk quizde 2xSKIP=20 iken SKIP_ALL=30.
                      skipAllOption: shouldOfferSkipAll(quiz)
                          ? RescuePowerOption(
                              type: PowerType.skipAll,
                              inventoryCount:
                                  ref.read(exchangeProvider).getCount('SKIP_ALL'),
                              diamondCost: quiz.purpleCostOf('SKIP_ALL'),
                            )
                          : null,
                      onRescue: onRescue,
                      onDeclineRescue: onDeclineRescue,
                    ),
                ],
              ),
      ),
    );
  }

}
