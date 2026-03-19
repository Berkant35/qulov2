import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class PowerUsageRow extends StatelessWidget {
  final Map<String, dynamic> powers;

  const PowerUsageRow({super.key, required this.powers});

  static const _powerIcons = {
    'oracle': QIcons.icOracle,
    'half': QIcons.icSplit,
    'hint': QIcons.icLightbulb,
    'time_extend': QIcons.icClock,
    'skip': QIcons.icSkipForward,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          children: _powerIcons.entries.map((entry) {
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
}
