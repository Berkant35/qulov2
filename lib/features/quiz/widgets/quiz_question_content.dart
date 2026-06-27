import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/data/models/quiz_model.dart' show QuizQuestionModel;
import 'package:qulo_v2/features/quiz/coach/quiz_power_coach_marks.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_banner.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

/// Displays the active quiz question, timer, answers, and power bar.
///
/// Converted from StatelessWidget to StatefulWidget solely to hold the
/// [_coachTried] guard that schedules the one-shot power-bar coach-mark tour
/// on the first build. All rendering behaviour is unchanged.
class QuizQuestionContent extends StatefulWidget {
  final QuizQuestionModel question;
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
  final VoidCallback onSheetOpening;
  final VoidCallback onSheetClosed;

  const QuizQuestionContent({
    super.key,
    required this.question,
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
    required this.onSheetOpening,
    required this.onSheetClosed,
  });

  @override
  State<QuizQuestionContent> createState() => _QuizQuestionContentState();
}

class _QuizQuestionContentState extends State<QuizQuestionContent> {
  /// One-shot guard — ensures the coach tour is scheduled only once per quiz
  /// session (widget lifetime). The service's SharedPreferences flag prevents
  /// it from ever showing again in subsequent sessions.
  bool _coachTried = false;

  @override
  void dispose() {
    CoachMarkService.instance.forceClose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStartPowerCoach();
  }

  void _maybeStartPowerCoach() {
    if (_coachTried) return;
    _coachTried = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoachMarkService.instance.maybeStartTour(
        context,
        tourId: 'quiz_powers',
        steps: buildQuizPowerCoachSteps(
          onPause: () => widget.timerKey.currentState?.pause(),
          onResume: () => widget.timerKey.currentState?.resume(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuizTimer(
            key: widget.timerKey,
            seconds: widget.question.timeLimitSeconds,
            questionId: widget.question.questionId,
            onTimeout: widget.onTimeout,
            onWarning: () {
              AnalyticsManager.instance.logEvent(
                AnalyticsEvents.quizTimerWarning,
                params: {
                  AnalyticsEvents.paramQuestionIndex:
                      widget.question.questionNumber,
                  AnalyticsEvents.paramSecondsRemaining: 10,
                },
              );
            },
            onCritical: () {
              AnalyticsManager.instance.logEvent(
                AnalyticsEvents.quizTimerCritical,
                params: {
                  AnalyticsEvents.paramQuestionIndex:
                      widget.question.questionNumber,
                  AnalyticsEvents.paramSecondsRemaining: 5,
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            widget.question.questionText,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (widget.oracleSuggestedIndex != null)
            PowerBanner(
              icon: Icons.auto_awesome,
              text: context.tr('power_oracle_desc'),
            ),
          if (widget.hintText != null && widget.hintText!.isNotEmpty)
            PowerBanner(
              icon: Icons.lightbulb_outline,
              text: widget.hintText!,
              color: context.appColors.warning,
            ),
          ...widget.question.answers.map((a) {
            final isRemoved = widget.removedIndices.contains(a.index);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AnswerButton(
                text: a.text,
                onTap: () {
                  if (!isRemoved) widget.onSelectAnswer(a.index);
                },
                isSelected: widget.selectedAnswerIndex == a.index,
                isOracleSuggested: widget.oracleSuggestedIndex == a.index,
                isDisabled: isRemoved,
              ),
            );
          }),
          if (widget.selectedAnswerIndex != null)
            _ConfirmButton(
              isSubmitting: widget.isSubmitting,
              onSubmitAnswer: widget.onSubmitAnswer,
            ),
          const Spacer(),
          PowerBar(
            sessionId: widget.sessionId,
            hasHint: widget.question.hasHint,
            onPowerUsed: widget.onPowerUsed,
            onSheetOpening: widget.onSheetOpening,
            onSheetClosed: widget.onSheetClosed,
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool isSubmitting;
  final Future<void> Function() onSubmitAnswer;

  const _ConfirmButton({
    required this.isSubmitting,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SafeTapButton(
        onTap: isSubmitting ? null : onSubmitAnswer,
        builder: (context, isLoading, onTap) => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            backgroundColor: context.appColors.primary,
          ),
          child: (isLoading || isSubmitting)
              ? AppLoadingWidget.small()
              : Text(
                  context.tr('quiz_confirm_answer'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
