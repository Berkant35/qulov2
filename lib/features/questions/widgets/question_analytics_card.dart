import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';
import 'package:qulo_v2/features/questions/widgets/answer_distribution_chart.dart';
import 'package:qulo_v2/features/questions/widgets/difficulty_badge.dart';
import 'package:qulo_v2/features/questions/widgets/green_earned_banner.dart';
import 'package:qulo_v2/features/questions/widgets/power_usage_row.dart';
import 'package:qulo_v2/features/questions/widgets/stat_chip.dart';
import 'package:qulo_v2/features/questions/widgets/success_rate_bar.dart';

class QuestionAnalyticsCard extends StatelessWidget {
  final QuestionAnalyticsItem item;

  const QuestionAnalyticsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = item.stats;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _QuestionCardHeader(item: item),
          const SizedBox(height: AppSpacing.md),

          // Question text
          Text(
            item.questionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),

          // Stats row
          Row(
            children: [
              StatChip(
                label: context.tr('analytics_correct'),
                value: '${stats.correct}',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              StatChip(
                label: context.tr('analytics_wrong'),
                value: '${stats.wrong}',
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.md),
              StatChip(
                label: context.tr('analytics_avg_time'),
                value: context
                    .tr('analytics_seconds')
                    .replaceAll('{n}', '${stats.avgTime}'),
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Success rate bar
          SuccessRateBar(successRate: stats.successRate),
          const SizedBox(height: AppSpacing.lg),

          // Power usage
          PowerUsageRow(powers: stats.powers),
          const SizedBox(height: AppSpacing.lg),

          // Answer distribution
          AnswerDistributionChart(distribution: stats.answerDistribution),
          const SizedBox(height: AppSpacing.md),

          // Green earned
          GreenEarnedBanner(greenEarned: stats.greenEarned),
        ],
      ),
    );
  }
}

class _QuestionCardHeader extends StatelessWidget {
  final QuestionAnalyticsItem item;

  const _QuestionCardHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          context
              .tr('analytics_question_num')
              .replaceAll('{n}', '${item.orderNum}'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        DifficultyBadge(difficulty: item.difficultyBadge),
        if (item.category != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              context.tr('question_category_${item.category}'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
