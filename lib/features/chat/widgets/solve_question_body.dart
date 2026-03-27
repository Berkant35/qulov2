import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_power_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_banner.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

class SolveQuestionBody extends StatelessWidget {
  final ChatQuestionModel question;
  final GlobalKey<QuizTimerState> timerKey;
  final String? selectedOption;
  final bool isSubmitting;
  final Set<String> removedOptions;
  final String? suggestedOption;
  final bool hintVisible;
  final String? hintText;
  final bool powerBlockActive;
  final VoidCallback onTimeout;
  final ValueChanged<String> onOptionSelected;
  final Future<void> Function() onSubmit;
  final Future<void> Function(String) onPowerTap;
  final Map<String, int> powerCounts;
  final int unblockCost;
  final String? senderPhotoUrl;
  final String? senderName;

  const SolveQuestionBody({
    super.key,
    required this.question,
    required this.timerKey,
    required this.selectedOption,
    required this.isSubmitting,
    required this.removedOptions,
    required this.suggestedOption,
    required this.hintVisible,
    required this.hintText,
    required this.powerBlockActive,
    required this.onTimeout,
    required this.onOptionSelected,
    required this.onSubmit,
    required this.onPowerTap,
    this.powerCounts = const {},
    this.unblockCost = 0,
    this.senderPhotoUrl,
    this.senderName,
  });

  static const _optionLabels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = question.allOptions;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sender info ──
          if (senderName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.appColors.surfaceElevated,
                    backgroundImage: senderPhotoUrl != null
                        ? CachedNetworkImageProvider(senderPhotoUrl!)
                        : null,
                    child: senderPhotoUrl == null
                        ? Icon(Icons.person, size: 20, color: context.appColors.textSecondary)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    senderName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          QuizTimer(
            key: timerKey,
            seconds: question.timeLimitSeconds,
            questionId: question.id,
            onTimeout: onTimeout,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            question.questionText,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (suggestedOption != null)
            PowerBanner(
              icon: Icons.auto_awesome,
              text: context.tr('power_oracle_desc'),
            ),
          if (hintVisible && hintText != null)
            PowerBanner(
              icon: Icons.lightbulb_outline,
              text: hintText!,
              color: Colors.amber,
            ),
          ...List.generate(options.length, (i) {
            final optionKey = _optionLabels[i];
            final isRemoved = removedOptions.contains(optionKey);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AnswerButton(
                text: options[i],
                onTap: () {
                  if (!isRemoved && !isSubmitting) {
                    onOptionSelected(optionKey);
                  }
                },
                isSelected: selectedOption == optionKey,
                isOracleSuggested: suggestedOption == optionKey,
                isDisabled: isRemoved,
              ),
            );
          }),
          if (selectedOption != null)
            _SubmitButton(
              isSubmitting: isSubmitting,
              onSubmit: onSubmit,
            ),
          const Spacer(),
          ChatQuestionPowerBar(
            optionCount: question.optionCount,
            isPowerBlocked: powerBlockActive,
            hasHint: question.hintText != null &&
                question.hintText!.isNotEmpty,
            onPowerTap: onPowerTap,
            unblockCost: unblockCost,
            disabledPowers: {
              if (suggestedOption != null) 'ORACLE',
              if (removedOptions.isNotEmpty) 'HALF',
              if (hintVisible) 'HINT',
            },
            powerCounts: powerCounts,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  const _SubmitButton({
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SafeTapButton(
        onTap: isSubmitting ? null : () => onSubmit(),
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
              ? const AppLoadingWidget.small()
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
