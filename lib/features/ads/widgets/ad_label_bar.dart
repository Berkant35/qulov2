import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Reklam kartının üst şeridi: belirgin "Reklam" etiketi. Yatay sürüklenince
/// kart geçilir (platform view reklam gövdesi jestleri yuttuğu için jest burada).
class AdLabelBar extends StatelessWidget {
  const AdLabelBar({super.key, this.onDragEnd});

  final GestureDragEndCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: onDragEnd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                context.tr('ad_label'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
