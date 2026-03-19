import 'package:flutter/material.dart';

import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/user_model.dart';

class DetailChips extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const DetailChips({
    super.key,
    required this.user,
    this.onTap,
  });

  String _frequencyLabel(BuildContext context, String? value) {
    switch (value) {
      case 'YES':
        return context.tr('freq_yes');
      case 'NO':
        return context.tr('freq_no');
      case 'SOMETIMES':
        return context.tr('freq_sometimes');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = user.details;

    final chips = <_ChipData>[
      _ChipData(
        icon: QIcons.icHeight,
        filled: details?.height != null,
        label: details?.height != null
            ? '${details!.height} cm'
            : context.tr('height'),
      ),
      _ChipData(
        icon: QIcons.icJob,
        filled: details?.job != null,
        label: details?.job ?? context.tr('job'),
      ),
      _ChipData(
        icon: QIcons.icSchool,
        filled: details?.school != null,
        label: details?.school ?? context.tr('school'),
      ),
      _ChipData(
        icon: QIcons.icZodiac,
        filled: details?.zodiac != null,
        label: details?.zodiac ?? context.tr('zodiac'),
      ),
      _ChipData(
        icon: QIcons.icSmoke,
        filled: details?.smoking != null,
        label: details?.smoking != null
            ? _frequencyLabel(context, details!.smoking)
            : context.tr('smoking'),
      ),
      _ChipData(
        icon: QIcons.icUseAlcohol,
        filled: details?.alcohol != null,
        label: details?.alcohol != null
            ? _frequencyLabel(context, details!.alcohol)
            : context.tr('alcohol'),
      ),
      _ChipData(
        icon: QIcons.icPets,
        filled: details?.pets != null,
        label: details?.pets ?? context.tr('pets'),
      ),
      _ChipData(
        icon: QIcons.icMusic,
        filled: details?.musicType != null,
        label: details?.musicType ?? context.tr('music'),
      ),
      _ChipData(
        icon: QIcons.icPersonality,
        filled: details?.personality != null,
        label: details?.personality ?? context.tr('personality'),
      ),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips.map((chip) => _DetailChipItem(chip: chip)).toList(),
      ),
    );
  }

}

class _DetailChipItem extends StatelessWidget {
  final _ChipData chip;

  const _DetailChipItem({required this.chip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFilled = chip.filled;

    final colors = theme.colorScheme;
    final bgColor =
        isFilled ? AppColors.primarySurface : colors.surface;
    final borderColor = isFilled
        ? AppColors.primary.withValues(alpha: 0.3)
        : colors.outline;
    final iconColor = isFilled
        ? AppColors.primary
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
          Text(
            chip.label,
            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
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

class _ChipData {
  final String icon;
  final bool filled;
  final String label;

  const _ChipData({
    required this.icon,
    required this.filled,
    required this.label,
  });
}
