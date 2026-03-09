import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class QuestionGateBanner extends StatelessWidget {
  final int questionCount;
  final int profileCompletion;
  final VoidCallback onAddQuestions;

  const QuestionGateBanner({
    super.key,
    required this.questionCount,
    required this.profileCompletion,
    required this.onAddQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = questionCount / 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(30),
            AppColors.secondary.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QIcon(QIcons.icLock, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('question_nudge_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('question_nudge_subtitle')
                .replaceAll('%{percent}', '$profileCompletion'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('question_nudge_progress')
                .replaceAll('{count}', '$questionCount'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddQuestions,
              icon: QIcon(QIcons.icPlus, color: theme.colorScheme.onPrimary, size: 18),
              label: Text(context.tr('question_nudge_add_button')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
