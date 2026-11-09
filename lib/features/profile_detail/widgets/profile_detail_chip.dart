import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

/// [ProfileDetailChip]'in view-model'i: ikon + gösterilecek (yerelleşmiş) etiket.
class ProfileDetailChipData {
  final String iconAsset;
  final String label;

  const ProfileDetailChipData({required this.iconAsset, required this.label});
}

/// Başkasının profilindeki tek bir detay chip'i (ikon + etiket).
class ProfileDetailChip extends StatelessWidget {
  final ProfileDetailChipData chip;

  const ProfileDetailChip({super.key, required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QIcon(chip.iconAsset, size: 16, color: context.appColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              chip.label,
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
