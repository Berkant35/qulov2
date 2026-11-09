import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Kart sürüklenirken köşedeki yön etiketi: sağa "Soruları çöz", sola "Reddet".
/// `Stack` içinde kullanılır (kendisi `Positioned` döner).
class DiscoverSwipeLabel extends StatelessWidget {
  final double dragOffset;

  const DiscoverSwipeLabel({super.key, required this.dragOffset});

  @override
  Widget build(BuildContext context) {
    final toRight = dragOffset > 0;

    return Positioned(
      top: AppSpacing.xl,
      left: toRight ? AppSpacing.xl : null,
      right: dragOffset < 0 ? AppSpacing.xl : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: toRight
              ? context.appColors.secondary.withValues(alpha: 0.9)
              : context.appColors.error.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.onScrim,
            width: 2,
          ),
        ),
        child: Text(
          toRight ? context.tr('solve_questions') : context.tr('reject'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.inkOnDark,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
