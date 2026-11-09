import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Güç kullanıldıktan sonraki tek satır ("2 yanlış şık silindi"): talimatın durduğu yerde,
/// karartmasız.
class PowerDemoResultLine extends StatelessWidget {
  const PowerDemoResultLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: AppSpacing.lg, color: colors.success),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
