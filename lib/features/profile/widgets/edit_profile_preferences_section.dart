import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';

class EditProfilePreferencesSection extends ConsumerWidget {
  final String completionText;

  const EditProfilePreferencesSection({
    super.key,
    required this.completionText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epState = ref.watch(editProfileProvider);
    final theme = Theme.of(context);
    final scale = context.fmt.radiusScale;

    return ProfileSectionCard(
      icon: Icons.tune,
      title: context.tr('preferences'),
      subtitle: context.tr('preferences_subtitle'),
      completionText: completionText,
      isComplete: completionText == '4/4',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender preference (locked)
          Text(
            context.tr('gender_preference'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _genderPrefLabel(context, epState.selectedGenderPref),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('gender_pref_locked_info'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Age range
          Text(
            '${context.tr('age_range')}: ${epState.ageRange.start.round()} - ${epState.ageRange.end.round()}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          RangeSlider(
            values: epState.ageRange,
            min: 18,
            max: 65,
            divisions: 47,
            labels: RangeLabels(
              epState.ageRange.start.round().toString(),
              epState.ageRange.end.round().toString(),
            ),
            activeColor: context.appColors.primary,
            inactiveColor: theme.colorScheme.surfaceContainerHigh,
            onChanged: (values) =>
                ref.read(editProfileProvider.notifier).setAgeRange(values),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Distance slider
          Text(
            '${context.tr('distance')}: ${context.fmt.radius(epState.distanceKm)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            value: scale.fromKm(epState.distanceKm),
            min: scale.min,
            max: scale.max,
            divisions: scale.divisions,
            label: scale.label(scale.fromKm(epState.distanceKm)),
            activeColor: context.appColors.primary,
            inactiveColor: theme.colorScheme.surfaceContainerHigh,
            onChanged: (value) => ref
                .read(editProfileProvider.notifier)
                .setDistanceKm(scale.toKm(value)),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Language preference
          Text(
            context.tr('language_preference'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children:
                AppConstants.supportedQuestionLocales.map((lang) {
              final isSelected = epState.selectedLanguages.contains(lang);
              final flag = AppConstants.localeFlagEmojis[lang] ?? '';
              return FilterChip(
                label: Text('$flag ${context.tr('locale_$lang')}'),
                selected: isSelected,
                onSelected: (_) =>
                    ref.read(editProfileProvider.notifier).toggleLanguage(lang),
                selectedColor: context.appColors.primarySurface,
                checkmarkColor: context.appColors.primary,
                side: BorderSide(
                  color: isSelected ? context.appColors.primary : context.appColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _genderPrefLabel(BuildContext context, String? pref) {
    switch (pref) {
      case 'MAN':
        return context.tr('male');
      case 'WOMAN':
        return context.tr('female');
      case 'BOTH':
        return context.tr('all');
      default:
        return context.tr('all');
    }
  }
}
