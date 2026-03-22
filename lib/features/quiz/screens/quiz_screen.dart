import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_feedback_overlay.dart';
import 'package:qulo_v2/features/quiz/widgets/power_banner.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/features/quiz/screens/match_celebration_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String targetId;
  final String? targetPhotoUrl;
  const QuizScreen({super.key, required this.targetId, this.targetPhotoUrl});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with QuizScreenMixin {
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
    final theme = Theme.of(context);
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
      return AppScaffold(
        title: '',
        leading: IconButton(
          icon: QIcon(QIcons.icX, size: 24),
          onPressed: onGoBack,
        ),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.appColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                quiz.failure is ServerFailure && (quiz.failure as ServerFailure).code == 'NO_QUESTIONS'
                    ? context.tr('quiz_no_questions')
                    : context.tr('quiz_start_error'),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onGoBack,
                child: Text(context.tr('quiz_go_back')),
              ),
            ],
          ),
        ),
      );
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
                          key: timerKey,
                          seconds: question.timeLimitSeconds,
                          questionId: question.questionId,
                          onTimeout: onTimeout,
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
                        if (oracleSuggestedIndex != null)
                          PowerBanner(
                            icon: Icons.auto_awesome,
                            text: context.tr('power_oracle_desc'),
                          ),
                        if (hintText != null && hintText!.isNotEmpty)
                          PowerBanner(
                            icon: Icons.lightbulb_outline,
                            text: hintText!,
                            color: context.appColors.warning,
                          ),
                        ...question.answers.map((a) {
                          final isRemoved = removedIndices.contains(a.index);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: AnswerButton(
                              text: a.text,
                              onTap: () {
                                if (!isRemoved) selectAnswer(a.index);
                              },
                              isSelected: selectedAnswerIndex == a.index,
                              isOracleSuggested: oracleSuggestedIndex == a.index,
                              isDisabled: isRemoved,
                            ),
                          );
                        }),
                        if (selectedAnswerIndex != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: SafeTapButton(
                              onTap: isSubmitting ? null : () => submitAnswer(),
                              builder: (context, isLoading, onTap) => ElevatedButton(
                                onPressed: onTap,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                  backgroundColor: context.appColors.primary,
                                ),
                                child: (isLoading || isSubmitting)
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
                          onPowerUsed: usePower,
                          onSheetOpening: () {
                            timerKey.currentState?.pause();
                            setState(() => isSheetOpen = true);
                          },
                          onSheetClosed: () {
                            timerKey.currentState?.resume();
                            setState(() => isSheetOpen = false);
                          },
                        ),
                      ],
                    ),
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
                        diamondCost: getPowerCost('SKIP'),
                      ),
                      skipAllOption: RescuePowerOption(
                        type: PowerType.skipAll,
                        inventoryCount: ref.read(exchangeProvider).getCount('SKIP_ALL'),
                        diamondCost: getPowerCost('SKIP_ALL'),
                      ),
                      onRescue: onRescue,
                      onDeclineRescue: onDeclineRescue,
                    ),
                ],
              ),
      ),
    );
  }
}
