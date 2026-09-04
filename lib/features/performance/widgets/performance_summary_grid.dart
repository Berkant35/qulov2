import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';

class PerformanceSummaryGrid extends StatelessWidget {
  final QuestionAnalyticsTotals totals;

  const PerformanceSummaryGrid({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          icon: Icons.check_circle_outline,
          iconColor: context.appColors.secondary,
          value: context.fmt.integer(totals.totalSolveCount),
          label: context.tr('total_solves'),
        ),
        _StatCard(
          icon: Icons.trending_up,
          iconColor: context.appColors.primary,
          value: context.fmt.percent(totals.overallSuccessRate),
          label: context.tr('success_rate'),
        ),
        _StatCard(
          iconWidget: const DiamondIcon.green(size: 20),
          value: context.fmt.integer(totals.totalGreenEarned),
          label: context.tr('green_earned'),
        ),
        _StatCard(
          iconWidget: const DiamondIcon.purple(size: 20),
          value: '-',
          label: context.tr('purple_spent'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final String value;
  final String label;

  const _StatCard({
    this.icon,
    this.iconColor,
    this.iconWidget,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          iconWidget ?? Icon(icon, size: 24, color: iconColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
