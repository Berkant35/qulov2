import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';
import 'package:qulo_v2/features/questions/widgets/analytics_stat_card.dart';

class AnalyticsTotalsSection extends StatelessWidget {
  final QuestionAnalyticsTotals totals;

  const AnalyticsTotalsSection({super.key, required this.totals});

  Color _successRateColor(int rate) {
    if (rate >= 70) return AppColors.success;
    if (rate >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
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
}
