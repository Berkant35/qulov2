import 'package:flutter/material.dart';

import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

/// [DetailChips] içindeki tek bir chip'in view-model'i.
class ChipData {
  final String icon;
  final bool filled;
  final String label;

  const ChipData({
    required this.icon,
    required this.filled,
    required this.label,
  });
}

/// Tek bir profil detay chip'ini çizer (ikon + etiket + boşsa ekle işareti).
class DetailChipItem extends StatelessWidget {
  final ChipData chip;

  const DetailChipItem({super.key, required this.chip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFilled = chip.filled;

    final colors = theme.colorScheme;
    final bgColor =
        isFilled ? context.appColors.primarySurface : colors.surface;
    final borderColor = isFilled
        ? context.appColors.primary.withValues(alpha: 0.3)
        : colors.outline;
    final iconColor = isFilled
        ? context.appColors.primary
        : colors.onSurfaceVariant.withValues(alpha: 0.4);
    final textColor = isFilled
        ? null
        : colors.onSurfaceVariant.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QIcon(chip.icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          // Serbest metin alanları (job/school/personality vb.) input tarafında
          // ProfileFieldLimits ile sınırlanır; burada da savunmacı olarak clamp'lenir
          // ki hiçbir koşulda chip satırı taşmasın.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.6,
            ),
            child: Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: textColor),
            ),
          ),
          if (!isFilled) ...[
            const SizedBox(width: 2),
            Icon(Icons.add, size: 12, color: iconColor),
          ],
        ],
      ),
    );
  }
}
