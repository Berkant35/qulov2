import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';
import 'package:qulo_v2/features/questions/widgets/analytics_stat_card.dart';
import 'package:qulo_v2/features/questions/widgets/difficulty_badge.dart';
import 'package:qulo_v2/providers/question_analytics_provider.dart';

class QuestionAnalyticsScreen extends ConsumerStatefulWidget {
  const QuestionAnalyticsScreen({super.key});

  @override
  ConsumerState<QuestionAnalyticsScreen> createState() =>
      _QuestionAnalyticsScreenState();
}

class _QuestionAnalyticsScreenState
    extends ConsumerState<QuestionAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logEvent(AnalyticsEvents.questionAnalyticsView);
    Future.microtask(
      () => ref.read(questionAnalyticsProvider.notifier).fetchAnalytics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionAnalyticsProvider);
    final analytics = state.valueOrNull;

    return AppScaffold(
      title: context.tr('analytics_title'),
      isLoading: state is AsyncLoading,
      padding: EdgeInsets.zero,
      body: analytics == null
          ? Center(
              child: Text(
                context.tr('analytics_no_data'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Totals Section ───
                  _buildTotalsSection(context, analytics.totals),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // ─── Best Question Highlight ───
                  if (analytics.totals.bestQuestionOrder != null)
                    _buildBestQuestion(context, analytics),
                  if (analytics.totals.bestQuestionOrder != null)
                    const SizedBox(height: AppSpacing.sectionGap),

                  // ─── Per-Question Cards ───
                  ...analytics.questions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _QuestionCard(item: item),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalsSection(
    BuildContext context,
    QuestionAnalyticsTotals totals,
  ) {
    return Row(
      children: [
        AnalyticsStatCard(
          label: context.tr('analytics_total_solves'),
          value: '${totals.totalSolveCount}',
          icon: QIcon(QIcons.icTarget, size: 24, color: AppColors.info),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnalyticsStatCard(
          label: context.tr('analytics_success_rate'),
          value: '%${totals.overallSuccessRate}',
          valueColor: _successRateColor(totals.overallSuccessRate),
          icon: QIcon(QIcons.icChart, size: 24, color: AppColors.warning),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnalyticsStatCard(
          label: context.tr('analytics_green_earned'),
          value: '${totals.totalGreenEarned}',
          valueColor: AppColors.secondary,
          icon: const DiamondIcon.green(size: 24, showGlow: false),
        ),
      ],
    );
  }

  Widget _buildBestQuestion(
    BuildContext context,
    QuestionAnalyticsResponse analytics,
  ) {
    final theme = Theme.of(context);
    final bestOrder = analytics.totals.bestQuestionOrder!;
    final bestItem = analytics.questions.where(
      (q) => q.orderNum == bestOrder,
    );
    if (bestItem.isEmpty) return const SizedBox.shrink();

    final item = bestItem.first;

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
                    color: AppColors.textPrimary,
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

  Color _successRateColor(int rate) {
    if (rate >= 70) return AppColors.success;
    if (rate >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Per-Question Card ───

class _QuestionCard extends StatelessWidget {
  final QuestionAnalyticsItem item;

  const _QuestionCard({required this.item});

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
          // ─── Header ───
          Row(
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
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Question text ───
          Text(
            item.questionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Stats row ───
          Row(
            children: [
              _StatChip(
                label: context.tr('analytics_correct'),
                value: '${stats.correct}',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                label: context.tr('analytics_wrong'),
                value: '${stats.wrong}',
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                label: context.tr('analytics_avg_time'),
                value: context
                    .tr('analytics_seconds')
                    .replaceAll('{n}', '${stats.avgTime}'),
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── Success rate progress bar ───
          _buildSuccessBar(context, stats.successRate),
          const SizedBox(height: AppSpacing.lg),

          // ─── Power usage row ───
          _buildPowerUsage(context, stats.powers),
          const SizedBox(height: AppSpacing.lg),

          // ─── Answer distribution ───
          _buildAnswerDistribution(context, stats.answerDistribution),
          const SizedBox(height: AppSpacing.md),

          // ─── Green earned ───
          if (stats.greenEarned > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DiamondIcon.green(size: 18, showGlow: false),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      context
                          .tr('analytics_green_question')
                          .replaceAll('{n}', '${stats.greenEarned}'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessBar(BuildContext context, int successRate) {
    final color = successRate >= 70
        ? AppColors.success
        : successRate >= 40
            ? AppColors.warning
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('analytics_success_rate'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            Text(
              '%$successRate',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: successRate / 100.0,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildPowerUsage(
    BuildContext context,
    Map<String, dynamic> powers,
  ) {
    final theme = Theme.of(context);
    final powerIcons = {
      'copy': QIcons.icCopy,
      'half': QIcons.icSplit,
      'hint': QIcons.icLightbulb,
      'time_extend': QIcons.icClock,
      'skip': QIcons.icSkipForward,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('analytics_power_usage'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: powerIcons.entries.map((entry) {
            final count = powers[entry.key] ?? 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QIcon(entry.value, size: 18, color: AppColors.primary),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnswerDistribution(
    BuildContext context,
    Map<String, dynamic> distribution,
  ) {
    final theme = Theme.of(context);
    final maxVal = distribution.values.fold<int>(
      0,
      (prev, v) => (v as int) > prev ? v : prev,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('analytics_answer_distribution'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(4, (i) {
          final key = 'answer_${i + 1}';
          final count = (distribution[key] ?? 0) as int;
          final fraction = maxVal > 0 ? count / maxVal : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    context
                        .tr('analytics_answer_n')
                        .replaceAll('{n}', '${i + 1}'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(
                          alpha: 0.4 + fraction * 0.6,
                        ),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Stat Chip ───

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
