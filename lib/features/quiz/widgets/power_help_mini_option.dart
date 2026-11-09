import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// "?" minyatüründe metinsiz şık (çerçeveli) ya da soru satırı ([filled]) yer tutucusu.
class PowerHelpMiniOption extends StatelessWidget {
  const PowerHelpMiniOption({super.key, required this.height, this.filled = false});

  static const double _borderAlpha = 0.6;

  final double height;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: filled ? colors.textHint : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: filled ? null : Border.all(color: colors.primary.withValues(alpha: _borderAlpha)),
      ),
    );
  }
}
