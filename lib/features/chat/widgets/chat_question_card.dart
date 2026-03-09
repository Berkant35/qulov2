import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';

class ChatQuestionCard extends StatelessWidget {
  final ChatQuestionModel question;
  final bool isMyQuestion;
  final Function(String)? onAnswer;

  const ChatQuestionCard({
    super.key,
    required this.question,
    required this.isMyQuestion,
    this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = question.hasUnmatchRisk
        ? AppColors.error.withValues(alpha: 0.6)
        : AppColors.primary.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning badge
          if (question.hasUnmatchRisk) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u26a0\ufe0f', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    'Bu soru riskli!',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Question text
          Text(
            question.questionText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Options
          if (!question.isAnswered && !isMyQuestion)
            _buildUnansweredOptions(context)
          else if (!question.isAnswered && isMyQuestion)
            _buildWaitingOptions(context)
          else
            _buildAnsweredOptions(context),
        ],
      ),
    );
  }

  /// Two tappable option buttons for the receiver
  Widget _buildUnansweredOptions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _OptionButton(
          label: 'A',
          text: question.optionA,
          theme: theme,
          onTap: () => onAnswer?.call('A'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionButton(
          label: 'B',
          text: question.optionB,
          theme: theme,
          onTap: () => onAnswer?.call('B'),
        ),
      ],
    );
  }

  /// Sender sees options as text + waiting hint
  Widget _buildWaitingOptions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionText(label: 'A', text: question.optionA, theme: theme),
        const SizedBox(height: AppSpacing.xs),
        _OptionText(label: 'B', text: question.optionB, theme: theme),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cevap bekleniyor...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textHint,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Options with color feedback after answering
  Widget _buildAnsweredOptions(BuildContext context) {
    final theme = Theme.of(context);
    final answeredOpt = question.answeredOption;
    final isCorrect = question.isCorrect ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnsweredOption(
          label: 'A',
          text: question.optionA,
          isSelected: answeredOpt == 'A',
          isCorrectChoice: isCorrect && answeredOpt == 'A',
          isWrongChoice: !isCorrect && answeredOpt == 'A',
          theme: theme,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AnsweredOption(
          label: 'B',
          text: question.optionB,
          isSelected: answeredOpt == 'B',
          isCorrectChoice: isCorrect && answeredOpt == 'B',
          isWrongChoice: !isCorrect && answeredOpt == 'B',
          theme: theme,
        ),
        // Unmatch result
        if (!isCorrect && question.hasUnmatchRisk) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unmatch gerceklesti',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Tappable option button for unanswered questions
class _OptionButton extends StatelessWidget {
  final String label;
  final String text;
  final ThemeData theme;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.label,
    required this.text,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceInput,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static option text for the sender's view
class _OptionText extends StatelessWidget {
  final String label;
  final String text;
  final ThemeData theme;

  const _OptionText({
    required this.label,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Option with color feedback after answering
class _AnsweredOption extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrectChoice;
  final bool isWrongChoice;
  final ThemeData theme;

  const _AnsweredOption({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrectChoice,
    required this.isWrongChoice,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surfaceInput;
    Color textColor = AppColors.textSecondary;
    Color labelColor = AppColors.textHint;

    if (isCorrectChoice) {
      bgColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
      labelColor = AppColors.success;
    } else if (isWrongChoice) {
      bgColor = AppColors.error.withValues(alpha: 0.15);
      textColor = AppColors.error;
      labelColor = AppColors.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: isCorrectChoice
                ? Icon(Icons.check, size: 14, color: labelColor)
                : isWrongChoice
                    ? Icon(Icons.close, size: 14, color: labelColor)
                    : Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
