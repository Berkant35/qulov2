import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class DiamondBalanceCard extends StatelessWidget {
  final int greenCount;
  final int purpleCount;

  const DiamondBalanceCard({
    super.key,
    required this.greenCount,
    required this.purpleCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: _BalanceSection(
              icon: const DiamondIcon.purple(size: 32, showGlow: true),
              count: purpleCount,
              label: context.tr('purple_diamonds'),
              color: context.appColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _BalanceSection(
              icon: const DiamondIcon.green(size: 32, showGlow: true),
              count: greenCount,
              label: context.tr('green_diamonds'),
              color: context.appColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  final Widget icon;
  final int count;
  final String label;
  final Color color;

  const _BalanceSection({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 48, width: 48, child: Center(child: icon)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$count',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
