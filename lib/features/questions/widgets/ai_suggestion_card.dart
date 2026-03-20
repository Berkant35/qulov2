import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';

class AiSuggestionCard extends StatelessWidget {
  final AiSuggestionModel suggestion;
  final VoidCallback onSelect;

  const AiSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          if (suggestion.category != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                context.tr('question_category_${suggestion.category}'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Question text
          Text(
            suggestion.questionText,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Answers
          ...List.generate(suggestion.answers.length, (i) {
            final isCorrect = i + 1 == suggestion.correctAnswer;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCorrect
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isCorrect
                            ? AppColors.secondary
                            : context.appColors.border,
                      ),
                    ),
                    child: isCorrect
                        ? Icon(Icons.check, size: 14, color: AppColors.secondary)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      suggestion.answers[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCorrect
                            ? AppColors.secondary
                            : context.appColors.textPrimary,
                        fontWeight:
                            isCorrect ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppSpacing.md),

          // Select button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSelect,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text(context.tr('ai_suggest_select')),
            ),
          ),
        ],
      ),
    );
  }
}
