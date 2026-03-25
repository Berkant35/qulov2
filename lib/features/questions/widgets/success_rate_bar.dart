import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class SuccessRateBar extends StatelessWidget {
  final int successRate;

  const SuccessRateBar({super.key, required this.successRate});

  Color _color(BuildContext context) {
    if (successRate >= 70) return context.appColors.success;
    if (successRate >= 40) return context.appColors.warning;
    return context.appColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(context);

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
              '%$successRate',
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
