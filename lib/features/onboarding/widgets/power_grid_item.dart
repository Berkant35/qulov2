import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class PowerGridItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final int index;
  final Animation<double> animation;

  const PowerGridItem({
    super.key,
    required this.iconPath,
    required this.label,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final begin = (index * 0.15).clamp(0.0, 1.0);
    final end = (begin + 0.3).clamp(0.0, 1.0);

    final staggered = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: staggered,
      builder: (context, child) {
        final value = staggered.value;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withAlpha(179),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
