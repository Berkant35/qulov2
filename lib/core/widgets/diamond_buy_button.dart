import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';

/// Elmas türlü fiyat butonu (güç satın alma). `dense`: Quiz satın alma sayfasındaki küçük çip.
class DiamondBuyButton extends StatelessWidget {
  final int cost;
  final DiamondType type;
  final bool isLoading;
  final VoidCallback onTap;
  final bool dense;

  const DiamondBuyButton({
    super.key,
    required this.cost,
    required this.type,
    required this.isLoading,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: dense ? 36 : 48,
                height: dense ? 18 : 20,
                child: const Center(child: AppLoadingWidget.small()),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DiamondIcon(type: type, size: dense ? 14 : 16, showGlow: false),
                  const SizedBox(width: AppSpacing.xs),
                  Text('$cost', style: textStyle?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
