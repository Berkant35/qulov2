import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';

class EditProfilePreferencesSection extends ConsumerWidget {
  final String completionText;
  final String Function(String code) languageLabelFn;

  const EditProfilePreferencesSection({
    super.key,
    required this.completionText,
    required this.languageLabelFn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epState = ref.watch(editProfileProvider);
    final theme = Theme.of(context);

    return ProfileSectionCard(
      icon: Icons.tune,
      title: context.tr('preferences'),
      subtitle: 'Sana uygun kisileri gorelim',
      completionText: completionText,
      isComplete: completionText == '4/4',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender preference
          Text(
            context.tr('gender_preference'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'MAN', label: Text(context.tr('male'))),
              ButtonSegment(value: 'WOMAN', label: Text(context.tr('female'))),
              ButtonSegment(value: 'BOTH', label: Text(context.tr('all'))),
            ],
            selected: {epState.selectedGenderPref ?? 'BOTH'},
            onSelectionChanged: (set) {
              ref.read(editProfileProvider.notifier).setGenderPref(set.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: context.appColors.primarySurface,
              selectedForegroundColor: context.appColors.primary,
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
            '${context.tr('distance')}: ${epState.distanceKm.round()} km',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            value: epState.distanceKm,
            min: 5,
            max: 200,
            divisions: 39,
            label: '${epState.distanceKm.round()} km',
            activeColor: context.appColors.primary,
            inactiveColor: theme.colorScheme.surfaceContainerHigh,
            onChanged: (value) =>
                ref.read(editProfileProvider.notifier).setDistanceKm(value),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Language preference
          Text(
            'Dil Tercihi',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children:
                ['tr', 'en', 'de', 'fr', 'ar', 'ru', 'es'].map((lang) {
              final isSelected = epState.selectedLanguages.contains(lang);
              return FilterChip(
                label: Text(languageLabelFn(lang)),
                selected: isSelected,
                onSelected: (_) =>
                    ref.read(editProfileProvider.notifier).toggleLanguage(lang),
                selectedColor: context.appColors.primary.withValues(alpha: 0.2),
                checkmarkColor: context.appColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
