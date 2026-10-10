import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Cevap detay kartındaki şık rozeti: üstte etiket, altında renkli halka içinde şık harfi.
class OptionBadge extends StatelessWidget {
  final String label;
  final String option;
  final Color color;

  const OptionBadge({
    super.key,
    required this.label,
    required this.option,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              option,
              style: textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
