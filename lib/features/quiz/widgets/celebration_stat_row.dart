import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class CelebrationStatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const CelebrationStatRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
