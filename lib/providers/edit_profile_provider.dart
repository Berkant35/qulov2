import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class EditProfileState {
  final bool isSaving;
  final String? selectedZodiac;
  final String? selectedSmoking;
  final String? selectedAlcohol;
  final String? selectedGenderPref;
  final RangeValues ageRange;
  final double distanceKm;
  final List<String?> photos;
  final String? selectedRelationshipGoal;
  final List<String> selectedLanguages;

  const EditProfileState({
    this.isSaving = false,
    this.selectedZodiac,
    this.selectedSmoking,
    this.selectedAlcohol,
    this.selectedGenderPref,
    this.ageRange = const RangeValues(18, 50),
    this.distanceKm = 50,
    this.photos = const [null, null, null, null, null, null],
    this.selectedRelationshipGoal,
    this.selectedLanguages = const [],
  });

  EditProfileState copyWith({
    bool? isSaving,
    String? Function()? selectedZodiac,
    String? Function()? selectedSmoking,
    String? Function()? selectedAlcohol,
    String? Function()? selectedGenderPref,
    RangeValues? ageRange,
    double? distanceKm,
    List<String?>? photos,
    String? Function()? selectedRelationshipGoal,
    List<String>? selectedLanguages,
  }) {
    return EditProfileState(
      isSaving: isSaving ?? this.isSaving,
      selectedZodiac:
          selectedZodiac != null ? selectedZodiac() : this.selectedZodiac,
      selectedSmoking:
          selectedSmoking != null ? selectedSmoking() : this.selectedSmoking,
      selectedAlcohol:
          selectedAlcohol != null ? selectedAlcohol() : this.selectedAlcohol,
      selectedGenderPref: selectedGenderPref != null
          ? selectedGenderPref()
          : this.selectedGenderPref,
      ageRange: ageRange ?? this.ageRange,
      distanceKm: distanceKm ?? this.distanceKm,
      photos: photos ?? this.photos,
      selectedRelationshipGoal: selectedRelationshipGoal != null
          ? selectedRelationshipGoal()
          : this.selectedRelationshipGoal,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
    );
  }
}

class EditProfileNotifier extends Notifier<EditProfileState> {
  @override
  EditProfileState build() {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return const EditProfileState();

    return EditProfileState(
      selectedZodiac: user.details?.zodiac,
      selectedSmoking: user.details?.smoking,
      selectedAlcohol: user.details?.alcohol,
      selectedGenderPref: user.genderPref,
      ageRange: RangeValues(
        (user.agePrefMin ?? 18).toDouble(),
        (user.agePrefMax ?? 50).toDouble(),
      ),
      distanceKm: user.matchRadiusKm.toDouble(),
      photos: List.generate(
        6,
        (i) => i < (user.photos?.length ?? 0) ? user.photos![i] : null,
      ),
      selectedRelationshipGoal: user.relationshipGoal,
      selectedLanguages: user.preferredLanguages.isNotEmpty
          ? user.preferredLanguages
          : [user.locale ?? 'tr'],
    );
  }

  void setZodiac(String? v) =>
      state = state.copyWith(selectedZodiac: () => v);
  void setSmoking(String? v) =>
      state = state.copyWith(selectedSmoking: () => v);
  void setAlcohol(String? v) =>
      state = state.copyWith(selectedAlcohol: () => v);
  void setAgeRange(RangeValues v) => state = state.copyWith(ageRange: v);
  void setDistanceKm(double v) => state = state.copyWith(distanceKm: v);
  void setRelationshipGoal(String? v) =>
      state = state.copyWith(selectedRelationshipGoal: () => v);
  void setLanguages(List<String> v) =>
      state = state.copyWith(selectedLanguages: v);
  void toggleLanguage(String lang) {
    final current = List<String>.from(state.selectedLanguages);
    if (current.contains(lang)) {
      if (current.length > 1) current.remove(lang); // En az 1 dil kalmalı
    } else {
      current.add(lang);
    }
    state = state.copyWith(selectedLanguages: current);
  }

  void refreshPhotos() {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;
    final p = user.photos ?? [];
    state = state.copyWith(
      photos: List.generate(6, (i) => i < p.length ? p[i] : null),
    );
  }

  Future<bool> saveProfile(
    Map<String, dynamic> profileData,
    Map<String, dynamic> detailsData,
  ) async {
    state = state.copyWith(isSaving: true);
    try {
      profileData.removeWhere((_, v) => v == null);
      final r1 =
          await ref.read(userProvider.notifier).updateProfile(profileData);
      detailsData.removeWhere((_, v) => v == null);
      final r2 =
          await ref.read(userProvider.notifier).updateDetails(detailsData);
      return r1.isSuccess && r2.isSuccess;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final editProfileProvider =
    NotifierProvider<EditProfileNotifier, EditProfileState>(
  EditProfileNotifier.new,
);
