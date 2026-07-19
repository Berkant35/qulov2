import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/profile_field_limits.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';

class EditProfileDetailsSection extends ConsumerWidget {
  final TextEditingController jobController;
  final TextEditingController schoolController;
  final TextEditingController petsController;
  final TextEditingController musicController;
  final TextEditingController personalityController;
  final String completionText;
  final List<DropdownMenuItem<String>> zodiacItems;
  final List<DropdownMenuItem<String>> frequencyItems;

  const EditProfileDetailsSection({
    super.key,
    required this.jobController,
    required this.schoolController,
    required this.petsController,
    required this.musicController,
    required this.personalityController,
    required this.completionText,
    required this.zodiacItems,
    required this.frequencyItems,
  });

  String? _guardValue(String? value, List<DropdownMenuItem<String>> items) {
    if (value == null) return null;
    final validValues = items.map((e) => e.value).toSet();
    return validValues.contains(value) ? value : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epState = ref.watch(editProfileProvider);

    return ProfileSectionCard(
      icon: Icons.interests,
      title: context.tr('details'),
      subtitle: context.tr('profile_details_subtitle'),
      completionText: completionText,
      isComplete: completionText == '8/8',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _guardValue(epState.selectedZodiac, zodiacItems),
            decoration: InputDecoration(labelText: context.tr('zodiac')),
            items: zodiacItems,
            onChanged: (v) =>
                ref.read(editProfileProvider.notifier).setZodiac(v),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          AppTextField(
            controller: jobController,
            label: context.tr('job'),
            hint: context.tr('job_hint'),
            maxLength: ProfileFieldLimits.job,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          AppTextField(
            controller: schoolController,
            label: context.tr('school'),
            hint: context.tr('school_hint'),
            maxLength: ProfileFieldLimits.school,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          DropdownButtonFormField<String>(
            initialValue: _guardValue(epState.selectedSmoking, frequencyItems),
            decoration: InputDecoration(labelText: context.tr('smoking')),
            items: frequencyItems,
            onChanged: (v) =>
                ref.read(editProfileProvider.notifier).setSmoking(v),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          DropdownButtonFormField<String>(
            initialValue: _guardValue(epState.selectedAlcohol, frequencyItems),
            decoration: InputDecoration(labelText: context.tr('alcohol')),
            items: frequencyItems,
            onChanged: (v) =>
                ref.read(editProfileProvider.notifier).setAlcohol(v),
            dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          AppTextField(
            controller: petsController,
            label: context.tr('pets'),
            hint: context.tr('pets_hint'),
            maxLength: ProfileFieldLimits.pets,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          AppTextField(
            controller: musicController,
            label: context.tr('music'),
            hint: context.tr('music_hint'),
            maxLength: ProfileFieldLimits.music,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          AppTextField(
            controller: personalityController,
            label: context.tr('personality'),
            hint: context.tr('personality_hint'),
            maxLength: ProfileFieldLimits.personality,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
