import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// "?" baloncuğunun metni: güç adı (güç renginde), tek cümle açıklama, varsa yüzde satırı.
class PowerHelpBubbleText extends StatelessWidget {
  const PowerHelpBubbleText({
    super.key,
    required this.title,
    required this.titleColor,
    required this.description,
    required this.accuracy,
  });

  final String title;
  final Color titleColor;
  final String description;

  /// Yalnız Kâhin'de ("%70 doğru").
  final String? accuracy;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final accuracy = this.accuracy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(color: titleColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(description, style: textTheme.bodySmall?.copyWith(color: colors.textPrimary)),
        if (accuracy != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            accuracy,
            style: textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}
