import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';

class BestQuestionHighlight extends StatelessWidget {
  final QuestionAnalyticsResponse analytics;

  const BestQuestionHighlight({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final bestOrder = analytics.totals.bestQuestionOrder;
    if (bestOrder == null) return const SizedBox.shrink();

    final bestItem = analytics.questions.where((q) => q.orderNum == bestOrder);
    if (bestItem.isEmpty) return const SizedBox.shrink();

    final item = bestItem.first;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          QIcon(QIcons.icCrown, size: 28, color: AppColors.gold),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('analytics_best_question'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.questionText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const DiamondIcon.green(size: 16, showGlow: false),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${item.stats.greenEarned}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
