import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';
import 'package:qulo_v2/features/questions/mixins/success_rate_color_mixin.dart';
import 'package:qulo_v2/features/questions/widgets/analytics_stat_card.dart';

class AnalyticsTotalsSection extends StatelessWidget with SuccessRateColorMixin {
  final QuestionAnalyticsTotals totals;

  const AnalyticsTotalsSection({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnalyticsStatCard(
          label: context.tr('analytics_total_solves'),
          value: context.fmt.integer(totals.totalSolveCount),
          icon: QIcon(QIcons.icTarget, size: 24, color: context.appColors.info),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnalyticsStatCard(
          label: context.tr('analytics_success_rate'),
          value: context.fmt.percent(totals.overallSuccessRate),
          valueColor: successRateColor(context, totals.overallSuccessRate),
          icon: QIcon(QIcons.icChart, size: 24, color: context.appColors.warning),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnalyticsStatCard(
          label: context.tr('analytics_green_earned'),
          value: context.fmt.integer(totals.totalGreenEarned),
          valueColor: context.appColors.secondary,
          icon: const DiamondIcon.green(size: 24, showGlow: false),
        ),
      ],
    );
  }
}
