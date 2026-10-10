import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/quiz_model.dart' show QuizQuestionModel;
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_banner.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_confirm_button.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/core/widgets/question_owner_header.dart';
import 'package:qulo_v2/features/quiz/models/quiz_target_args.dart';

/// Displays the active quiz question, timer, answers, and power bar.
class QuizQuestionContent extends StatelessWidget {
  final QuizQuestionModel question;
  /// Sorusu cozulen kisi — isim/foto/mesafe (yoksa satir gizlenir).
  final QuizTargetArgs? target;
  final GlobalKey<QuizTimerState> timerKey;
  final String sessionId;
  final int? selectedAnswerIndex;
  final int? oracleSuggestedIndex;
  final List<int> removedIndices;
  final String? hintText;
  final bool isSubmitting;
  final VoidCallback onTimeout;
  final ValueChanged<int> onSelectAnswer;
  final Future<void> Function() onSubmitAnswer;
  final Future<void> Function(String power) onPowerUsed;

  const QuizQuestionContent({
    super.key,
    required this.question,
    this.target,
    required this.timerKey,
    required this.sessionId,
    required this.selectedAnswerIndex,
    required this.oracleSuggestedIndex,
    required this.removedIndices,
    required this.hintText,
    required this.isSubmitting,
    required this.onTimeout,
    required this.onSelectAnswer,
    required this.onSubmitAnswer,
    required this.onPowerUsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionOwnerHeader(
            name: target?.name,
            photoUrl: target?.photoUrl,
            distanceKm: target?.distanceKm,
          ),
          QuizTimer(
            key: timerKey,
            seconds: question.startSeconds,
            totalSeconds: question.timeLimitSeconds,
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
                  if (!isRemoved) onSelectAnswer(a.index);
                },
                isSelected: selectedAnswerIndex == a.index,
                isOracleSuggested: oracleSuggestedIndex == a.index,
                isDisabled: isRemoved,
              ),
            );
          }),
          if (selectedAnswerIndex != null)
            QuizConfirmButton(
              isSubmitting: isSubmitting,
              onSubmitAnswer: onSubmitAnswer,
            ),
          const Spacer(),
          PowerBar(
            sessionId: sessionId,
            hasHint: question.hasHint,
            onPowerUsed: onPowerUsed,
          ),
        ],
      ),
    );
  }
}
