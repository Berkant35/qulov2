import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class SuccessRateBar extends StatelessWidget {
  final int successRate;

  const SuccessRateBar({super.key, required this.successRate});

  Color get _color {
    if (successRate >= 70) return AppColors.success;
    if (successRate >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: _color,
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
            valueColor: AlwaysStoppedAnimation<Color>(_color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
