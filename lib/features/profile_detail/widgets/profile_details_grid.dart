import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';

class ProfileDetailsGrid extends StatelessWidget {
  final UserDetailsModel details;
  const ProfileDetailsGrid({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('details'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: items,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final items = <Widget>[];

    if (details.height != null) {
      items.add(_DetailChip(
        iconAsset: QIcons.icHeight,
        label: '${details.height} cm',
      ));
    }
    if (details.zodiac != null && details.zodiac!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icZodiac,
        label: details.zodiac!,
      ));
    }
    if (details.job != null && details.job!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icJob,
        label: details.job!,
      ));
    }
    if (details.school != null && details.school!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icSchool,
        label: details.school!,
      ));
    }
    if (details.smoking != null && details.smoking!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icSmoke,
        label: _translateEnum(context, details.smoking!),
      ));
    }
    if (details.alcohol != null && details.alcohol!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icUseAlcohol,
        label: _translateEnum(context, details.alcohol!),
      ));
    }
    if (details.pets != null && details.pets!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icPets,
        label: details.pets!,
      ));
    }
    if (details.musicType != null && details.musicType!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icMusic,
        label: details.musicType!,
      ));
    }
    if (details.personality != null && details.personality!.isNotEmpty) {
      items.add(_DetailChip(
        iconAsset: QIcons.icPersonality,
        label: details.personality!,
      ));
    }

    return items;
  }

  String _translateEnum(BuildContext context, String value) {
    return switch (value.toUpperCase()) {
      'YES' => context.tr('yes'),
      'NO' => context.tr('no'),
      'SOMETIMES' => context.tr('sometimes'),
      _ => value,
    };
  }
}

class _DetailChip extends StatelessWidget {
  final String iconAsset;
  final String label;
  const _DetailChip({required this.iconAsset, required this.label});

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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QIcon(iconAsset, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
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
