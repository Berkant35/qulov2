import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/core/widgets/milestone_celebration_sheet.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/providers/user_languages_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_units.dart';
import 'package:qulo_v2/features/profile/screens/edit_profile_screen.dart';
import 'package:qulo_v2/features/profile/widgets/profile_save_success_sheet.dart';
import 'package:qulo_v2/routing/route_names.dart';

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

  // ─── Photo Actions ───

  void onPhotoSlotTap(int index) {
    final photos = ref.read(editProfileProvider).photos;
    final hasPhoto = photos[index] != null;

    if (hasPhoto) {
      _showExistingPhotoSheet(index);
    } else {
      _showPickPhotoSheet(index);
    }
  }

  void _showExistingPhotoSheet(int index) {
    final nav = ref.read(navigationServiceProvider);

    nav.showAppBottomSheet<String>(
      ListBottomSheet<String>(
        name: 'photo_options',
        title: context.tr('photo_options'),
        options: [
          SheetOption(
            icon: Icons.star,
            label: context.tr('make_primary'),
            value: 'primary',
          ),
          SheetOption(
            icon: Icons.delete,
            label: context.tr('delete_photo'),
            value: 'delete',
          ),
        ],
      ),
    ).then((result) {
      if (result == null) return;
      if (result == 'primary') {
        _makePrimary(index);
      } else if (result == 'delete') {
        _confirmDeletePhoto(index);
      }
    });
  }

  void _showPickPhotoSheet(int index) {
    final nav = ref.read(navigationServiceProvider);

    nav.showAppBottomSheet<String>(
      ListBottomSheet<String>(
        name: 'pick_photo_source',
        title: context.tr('add_photo'),
        options: [
          SheetOption(
            icon: Icons.photo_library,
            label: context.tr('gallery'),
            value: 'gallery',
          ),
          SheetOption(
            icon: Icons.camera_alt,
            label: context.tr('camera'),
            value: 'camera',
          ),
        ],
      ),
    ).then((result) {
      if (result == null) return;
      if (result == 'gallery') {
        _pickCropAndUpload(ImageSource.gallery);
      } else if (result == 'camera') {
        _pickCropAndUpload(ImageSource.camera);
      }
    });
  }

  Future<void> _pickCropAndUpload(ImageSource source) async {
    final PickedImage? picked;
    try {
      picked = await ref
          .read(imagePickerManagerProvider)
          .pickAndCrop(context, source);
    } on ImagePickerPermissionException catch (e) {
      if (mounted) {
        await showImagePickerPermissionDialog(
          ref,
          context,
          isCamera: e.isCamera,
        );
      }
      return;
    }
    if (picked == null) return;

    final result = await ref
        .read(userProvider.notifier)
        .uploadPhoto(picked.bytes, picked.mimeType);

    if (mounted) {
      if (result.isSuccess) {
        final photos = ref.read(editProfileProvider).photos;
        final photoIndex = photos.indexWhere((p) => p == null);
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.profilePhotoAdd,
          params: {
            AnalyticsEvents.paramPhotoIndex:
                photoIndex >= 0 ? photoIndex : photos.length,
            AnalyticsEvents.paramSource:
                source == ImageSource.gallery ? 'gallery' : 'camera',
          },
        );
        ref.read(editProfileProvider.notifier).refreshPhotos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('save_error'))),
        );
      }
    }
  }

  void _makePrimary(int index) {
    final photos = ref.read(editProfileProvider).photos;
    final currentPhotos = photos.whereType<String>().toList();
    if (index >= currentPhotos.length) return;

    final photo = currentPhotos.removeAt(index);
    currentPhotos.insert(0, photo);

    ref.read(userProvider.notifier).reorderPhotos(currentPhotos).then((_) {
      ref.read(editProfileProvider.notifier).refreshPhotos();
    });
  }

  void _confirmDeletePhoto(int index) {
    final nav = ref.read(navigationServiceProvider);

    nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'delete_photo_confirm',
        title: context.tr('delete_photo'),
        message: context.tr('delete_photo_confirm'),
        confirmText: context.tr('delete'),
        isDestructive: true,
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.profilePhotoRemove,
          params: {AnalyticsEvents.paramPhotoIndex: index},
        );
        ref.read(userProvider.notifier).deletePhoto(index).then((_) {
          ref.read(editProfileProvider.notifier).refreshPhotos();
        });
      }
    });
  }

  // ─── Location Update ───

  Future<void> updateLocation() async {
    await ref.read(locationProvider.notifier).getCurrentLocation();
    final loc = ref.read(locationProvider);
    if (loc.lat != null && loc.lng != null) {
      await ref
          .read(userProvider.notifier)
          .updateLocation(lat: loc.lat!, lng: loc.lng!);
      await ref.read(userProvider.notifier).fetchMe();
      final user = ref.read(userProvider).valueOrNull;
      if (user != null && user.city != null) {
        setState(() {
          cityController.text = user.city!;
        });
      }
    }
  }

  // ─── Save ───

  Future<void> save() async {
    final epState = ref.read(editProfileProvider);
    final notifier = ref.read(editProfileProvider.notifier);

    // Snapshot rewards before save for milestone detection
    final oldClaimed = ref.read(userProvider.notifier).currentRewardsClaimed;

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
      // Sync: userLanguagesProvider'ı userProvider'dan güncelle
      ref.read(userLanguagesProvider.notifier).syncFromUser();
    }

    if (mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('save_error'))),
        );
        return;
      }

      // Detect newly claimed milestones
      final newMilestones =
          ref.read(userProvider.notifier).detectNewMilestones(oldClaimed);

      if (newMilestones.isNotEmpty) {
        final milestoneRewards = ref.read(economyConfigProvider).rewards.milestones;
        final highestMilestone = newMilestones.last;

        await ref.read(navigationServiceProvider).showAppBottomSheet(
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
      if (mounted) {
        await ref.read(navigationServiceProvider).showAppBottomSheet(
          CustomBottomSheet(
            name: 'profile_save_success',
            builder: (_) => ProfileSaveSuccessSheet(
              onPreview: () {
                ref.read(navigationServiceProvider).closeOverlay();
                AnalyticsManager.instance.logEvent(
                  AnalyticsEvents.saveSuccessPreviewTapped,
                );
                ref.read(navigationServiceProvider).push(
                  RouteNames.profilePreview,
                  extra: 'edit_screen',
                );
              },
            ),
          ),
        );
      }
    }
  }

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
    const signs = [
      'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
      'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces',
    ];
    return signs
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
