import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class PrefChip extends StatelessWidget {
  final dynamic iconPath; // String (old icons) or IconRef (new icons)
  final String label;

  const PrefChip({
    super.key,
    required this.iconPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.appColors.secondarySurface,
        border: Border.all(color: context.appColors.secondary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath is String)
            QIcon(iconPath, size: 14, color: context.appColors.secondary)
          else
            AppIcon(iconPath, size: 14, color: context.appColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
