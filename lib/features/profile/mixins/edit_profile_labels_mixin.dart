import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_screen_mixin.dart';

/// Tamamlanma metinleri, milestone ilerleme mesaji ve dropdown item
/// builder'lari — sunum disi pure fonksiyonlar.
mixin EditProfileLabelsMixin on EditProfileScreenMixin {
  // ─── Completion Helpers ───

  String photoCompletionText(List<String?> photos) {
    final count = photos.where((p) => p != null).length;
    return '$count/6';
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

  int? nextMilestone(int completion) {
    final milestones = ref.read(economyConfigProvider).rewards.milestones;
    final sortedKeys = milestones.keys.toList()..sort();
    for (final m in sortedKeys) {
      if (completion < m) return m;
    }
    return null;
  }

  String milestoneMessage(int completion) {
    final next = nextMilestone(completion);
    final rewards = ref.read(economyConfigProvider).rewards.milestones;
    if (next == null) return '';
    return '%$next tamamla, ${rewards[next]} elmas kazan!';
  }

  String languageLabel(String code) {
    return switch (code) {
      'tr' => 'Turkce',
      'en' => 'English',
      'de' => 'Deutsch',
      'fr' => 'Francais',
      'ar' => '\u0627\u0644\u0639\u0631\u0628\u064A\u0629',
      'ru' => '\u0420\u0443\u0441\u0441\u043A\u0438\u0439',
      'es' => 'Espanol',
      _ => code,
    };
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
