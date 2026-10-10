import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Sayfa göstergesi (ince çubuklar) — profil galerisi ve banner carousel ortak.
class PageBarIndicator extends StatelessWidget {
  const PageBarIndicator({
    super.key,
    required this.count,
    required this.current,
    this.activeColor = AppColors.onScrim,
    this.inactiveColor,
  });

  final int count;
  final int current;
  final Color activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    final inactive = inactiveColor ?? activeColor.withValues(alpha: 0.4);
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.symmetric(horizontal: count > 6 ? 1 : 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
              color: i == current ? activeColor : inactive,
            ),
          ),
        );
      }),
    );
  }
}
