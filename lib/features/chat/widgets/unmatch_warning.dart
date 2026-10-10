import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Sonuç ekranında "eşleşme sona erdi" uyarısı (yanlış cevap eşleşmeyi bitirdiyse).
class UnmatchWarning extends StatelessWidget {
  const UnmatchWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final errorColor = context.appColors.error;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: errorColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.tr('result_unmatch_ended'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: errorColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
