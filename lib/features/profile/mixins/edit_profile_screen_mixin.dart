import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/core/widgets/milestone_celebration_sheet.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/providers/user_languages_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/features/profile/models/edit_profile_units.dart';
import 'package:qulo_v2/features/profile/screens/edit_profile_screen.dart';
import 'package:qulo_v2/features/profile/widgets/profile_save_success_sheet.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Edit profile ekraninin paylasilan durumu: controller'lar, yasam dongusu,
/// konum guncelleme ve kaydetme.
///
/// Domain mixin'leri (`EditProfilePhotosMixin`, `EditProfileLabelsMixin`) bunun
/// uzerine biner. Boylece her dosya tek bir konuyla ilgileniyor — eski tek parca
/// mixin 453 satira cikmisti (limit 300).
mixin EditProfileScreenMixin on ConsumerState<EditProfileScreen> {
  // ─── Controllers ───
  final bioController = TextEditingController();
  final nameController = TextEditingController();
  final cityController = TextEditingController();
  final jobController = TextEditingController();
  final schoolController = TextEditingController();
  final petsController = TextEditingController();
  final musicController = TextEditingController();
  final personalityController = TextEditingController();

  // ─── Birimler (boy/kilo) ───
  late final units = EditProfileUnits(ref.read(formatManagerProvider));

  void initMixin() {
    // Duzenleme durumu (foto izgarasi, tercihler) her acilista kullanicidan yeniden
    // tohumlanir: saglayici uygulama kapsaminda ve `build()` kullaniciyi bir kez okur.
    // Eskiden kaydedilmemis secimler sonraki acilisa tasiniyor, baska yoldan degisen
    // yaricap/foto eski gorunuyor, eski izgaradaki indeksle yanlis foto silinebiliyordu.
    // `ref.invalidate` initState'te miras bagimliligi kurar (assert): kapsam listen'siz alinir.
    ProviderScope.containerOf(context, listen: false).invalidate(editProfileProvider);
    _loadControllers();
    _addCompletionListeners();
  }

  void disposeMixin() {
    // Remove listeners before dispose
    for (final c in _completionControllers) {
      c.removeListener(_onCompletionFieldChanged);
    }
    bioController.dispose();
    nameController.dispose();
    cityController.dispose();
    jobController.dispose();
    schoolController.dispose();
    petsController.dispose();
    musicController.dispose();
    personalityController.dispose();
    units.dispose();
  }

  List<TextEditingController> get _completionControllers => [
        bioController,
        nameController,
        cityController,
        units.heightCmField,
        units.heightFeet,
        units.heightInches,
        units.weight,
        jobController,
        schoolController,
        petsController,
        musicController,
        personalityController,
      ];

  void _addCompletionListeners() {
    for (final c in _completionControllers) {
      c.addListener(_onCompletionFieldChanged);
    }
  }

  void _onCompletionFieldChanged() {
    // Trigger rebuild so section completion texts update reactively
    if (mounted) setState(() {});
  }

  void _loadControllers() {
    final userAsync = ref.read(userProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return;

    bioController.text = user.bio ?? '';
    nameController.text = user.name ?? '';
    cityController.text = user.city ?? '';
    units.load(heightCm: user.details?.height, weightKg: user.details?.weight);
    jobController.text = user.details?.job ?? '';
    schoolController.text = user.details?.school ?? '';
    petsController.text = user.details?.pets ?? '';
    musicController.text = user.details?.musicType ?? '';
    personalityController.text = user.details?.personality ?? '';
  }

  // ─── Location Update ───

  /// Kullanicinin baslattigi konum guncellemesi ekran kapansa da tamamlanir (sunucu
  /// konumu + kullanici tazelemesi): kapsam await ONCESI alinir. Eskiden kapali ekranda
  /// `fetchMe` atlaniyor, sehir/konum bayat kaliyordu. Yalniz sehir alani acik ekrana bagli.
  Future<void> updateLocation() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final users = container.read(userProvider.notifier);
    await container.read(locationProvider.notifier).getCurrentLocation();
    final loc = container.read(locationProvider);
    if (loc.lat == null || loc.lng == null) return;

    await users.updateLocation(lat: loc.lat!, lng: loc.lng!);
    await users.fetchMe();
    if (!mounted) return;

    final city = ref.read(userProvider).valueOrNull?.city;
    if (city != null) {
      setState(() => cityController.text = city);
    }
  }

  // ─── Save ───

  /// Kaydet. Bağımlılıklar await ÖNCESİ alınır: kayıt sürerken geri dönülürse
  /// sunucu kaydı yine tamamlanır ve dil listesi ([userLanguagesProvider])
  /// eşitlenir — eskiden kapalı ekranda `ref` StateError atıyordu, eşitleme
  /// düşüyordu. Sonuç sayfaları/snackbar yalnız açık ekranda.
  Future<void> save() async {
    final epState = ref.read(editProfileProvider);
    final notifier = ref.read(editProfileProvider.notifier);
    final users = ref.read(userProvider.notifier);
    final userLanguages = ref.read(userLanguagesProvider.notifier);
    final nav = ref.read(navigationServiceProvider);

    // Snapshot rewards before save for milestone detection
    final oldClaimed = users.currentRewardsClaimed;

    final profileData = <String, dynamic>{
      'bio': bioController.text.trim(),
      'city': cityController.text.trim(),
      'age_pref_min': epState.ageRange.start.round(),
      'age_pref_max': epState.ageRange.end.round(),
      'match_radius_km': epState.distanceKm.round(),
      'relationship_goal': epState.selectedRelationshipGoal,
      'preferred_languages': epState.selectedLanguages,
    };

    final detailsData = <String, dynamic>{
      'height': units.heightCm(),
      'weight': units.weightKg(),
      'zodiac': epState.selectedZodiac,
      'job': jobController.text.trim(),
      'school': schoolController.text.trim(),
      'smoking': epState.selectedSmoking,
      'alcohol': epState.selectedAlcohol,
      'pets': petsController.text.trim(),
      'music_type': musicController.text.trim(),
      'personality': personalityController.text.trim(),
    };

    final success = await notifier.saveProfile(profileData, detailsData);

    if (success) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.profileEditSave);
      // Sync: userLanguagesProvider'i userProvider'dan guncelle
      userLanguages.syncFromUser();
    }

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('error_general'))),
      );
      return;
    }

    // Detect newly claimed milestones
    final newMilestones = users.detectNewMilestones(oldClaimed);

    if (newMilestones.isNotEmpty) {
      final milestoneRewards = ref.read(economyConfigProvider).rewards.milestones;
      final highestMilestone = newMilestones.last;

      await nav.showAppBottomSheet(
        CustomBottomSheet(
          name: 'milestone_celebration',
          builder: (_) => MilestoneCelebrationSheet(
            milestone: highestMilestone,
            reward: milestoneRewards[highestMilestone] ?? 0,
          ),
        ),
      );
    }

    // Show success sheet (after milestone if any)
    if (!mounted) return;
    await nav.showAppBottomSheet(
      CustomBottomSheet(
        name: 'profile_save_success',
        builder: (_) => ProfileSaveSuccessSheet(
          onPreview: () {
            nav.closeOverlay();
            AnalyticsManager.instance.logEvent(
              AnalyticsEvents.saveSuccessPreviewTapped,
            );
            nav.push(RouteNames.profilePreview, extra: 'edit_screen');
          },
        ),
      ),
    );
  }
}
