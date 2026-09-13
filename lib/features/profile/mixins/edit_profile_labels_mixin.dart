import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_screen_mixin.dart';
import 'package:qulo_v2/features/profile/utils/milestone_utils.dart';

/// Tamamlanma metinleri, milestone ilerleme mesaji ve dropdown item
/// builder'lari — sunum disi pure fonksiyonlar.
mixin EditProfileLabelsMixin on EditProfileScreenMixin {
  // ─── Completion Helpers ───

  String photoCompletionText(List<String?> photos) {
    final count = photos.where((p) => p != null).length;
    return '$count/${AppConstants.maxPhotos}';
  }

  String basicInfoCompletionText() {
    int filled = 0;
    if (nameController.text.trim().isNotEmpty) filled++;
    if (cityController.text.trim().isNotEmpty) filled++;
    if (units.heightCm() != null) filled++;
    if (units.weightKg() != null) filled++;
    return '$filled/4';
  }

  String detailsCompletionText(EditProfileState epState) {
    int filled = 0;
    if (epState.selectedZodiac != null) filled++;
    if (jobController.text.trim().isNotEmpty) filled++;
    if (schoolController.text.trim().isNotEmpty) filled++;
    if (epState.selectedSmoking != null) filled++;
    if (epState.selectedAlcohol != null) filled++;
    if (petsController.text.trim().isNotEmpty) filled++;
    if (musicController.text.trim().isNotEmpty) filled++;
    if (personalityController.text.trim().isNotEmpty) filled++;
    return '$filled/8';
  }

  String preferencesCompletionText(EditProfileState epState) {
    int filled = 0;
    if (epState.selectedGenderPref != null) filled++;
    filled++; // age range always set
    filled++; // distance always set
    if (epState.selectedLanguages.isNotEmpty) filled++;
    return '$filled/4';
  }

  // ─── Progress Helpers ───

  /// Eskiden Turkce sabitti ('%50 tamamla, 20 elmas kazan!') — Turkce olmayan
  /// her kullanici profil duzenlemede Turkce metin goruyordu.
  String milestoneMessage(int completion) {
    final rewards = ref.read(economyConfigProvider).rewards.milestones;
    final next = nextMilestoneFor(completion, rewards.keys);
    if (next == null) return '';
    return context
        .tr('milestone_progress_hint')
        .replaceAll('{percent}', '$next')
        .replaceAll('{diamonds}', '${rewards[next]}');
  }

  // ─── Dropdown Helpers ───

  List<DropdownMenuItem<String>> zodiacItems() {
    return AppConstants.zodiacSigns
        .map((s) => DropdownMenuItem(
              value: s,
              child: Text(context.tr('zodiac_$s')),
            ))
        .toList();
  }

  List<DropdownMenuItem<String>> frequencyItems() {
    return [
      DropdownMenuItem(value: 'YES', child: Text(context.tr('freq_yes'))),
      DropdownMenuItem(value: 'NO', child: Text(context.tr('freq_no'))),
      DropdownMenuItem(
          value: 'SOMETIMES', child: Text(context.tr('freq_sometimes'))),
    ];
  }
}
