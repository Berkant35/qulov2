import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Bakiye kartında tek elmas türünün sütunu: ikon, sayı, etiket.
class DiamondBalanceSection extends StatelessWidget {
  final Widget icon;
  final int count;
  final String label;
  final Color color;

  const DiamondBalanceSection({
    super.key,
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
        const SizedBox(height: AppSpacing.xxs),
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

/// Bakiye sütunları arasındaki dikey ayraç.
class DiamondBalanceDivider extends StatelessWidget {
  const DiamondBalanceDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
