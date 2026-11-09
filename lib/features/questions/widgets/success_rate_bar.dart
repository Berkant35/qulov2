import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/questions/mixins/success_rate_color_mixin.dart';

class SuccessRateBar extends StatelessWidget with SuccessRateColorMixin {
  final int successRate;

  const SuccessRateBar({super.key, required this.successRate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = successRateColor(context, successRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('analytics_success_rate'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            Text(
              context.fmt.percent(successRate),
              style: theme.textTheme.labelSmall?.copyWith(
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
            backgroundColor: context.appColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
