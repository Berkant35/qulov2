import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/features/profile/widgets/photo_grid.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // ─── Controllers ───
  final _bioController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _jobController = TextEditingController();
  final _schoolController = TextEditingController();
  final _petsController = TextEditingController();
  final _musicController = TextEditingController();
  final _personalityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadControllers();
  }

  void _loadControllers() {
    final userAsync = ref.read(userProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return;

    _bioController.text = user.bio ?? '';
    _nameController.text = user.name ?? '';
    _cityController.text = user.city ?? '';
    _heightController.text = user.details?.height?.toString() ?? '';
    _weightController.text = user.details?.weight?.toString() ?? '';
    _jobController.text = user.details?.job ?? '';
    _schoolController.text = user.details?.school ?? '';
    _petsController.text = user.details?.pets ?? '';
    _musicController.text = user.details?.musicType ?? '';
    _personalityController.text = user.details?.personality ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _jobController.dispose();
    _schoolController.dispose();
    _petsController.dispose();
    _musicController.dispose();
    _personalityController.dispose();
    super.dispose();
  }

  // ─── Photo Actions ───

  void _onPhotoSlotTap(int index) {
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
        _pickFromGallery();
      } else if (result == 'camera') {
        _pickFromCamera();
      }
    });
  }

  Future<void> _pickFromGallery() => _pickCropAndUpload(ImageSource.gallery);

  Future<void> _pickFromCamera() => _pickCropAndUpload(ImageSource.camera);

  Future<void> _pickCropAndUpload(ImageSource source) async {
    final picked = await ref.read(imagePickerManagerProvider).pickAndCrop(context, source);
    if (picked == null) return;

    final result = await ref.read(userProvider.notifier).uploadPhoto(picked.bytes, picked.mimeType);

    if (mounted) {
      if (result.isSuccess) {
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
        ref.read(userProvider.notifier).deletePhoto(index).then((_) {
          ref.read(editProfileProvider.notifier).refreshPhotos();
        });
      }
    });
  }

  // ─── Location Update ───

  Future<void> _updateLocation() async {
    await ref.read(locationProvider.notifier).getCurrentLocation();
    final loc = ref.read(locationProvider);
    if (loc.lat != null && loc.lng != null) {
      await ref.read(userProvider.notifier).updateLocation(lat: loc.lat!, lng: loc.lng!);
      await ref.read(userProvider.notifier).fetchMe();
      final user = ref.read(userProvider).valueOrNull;
      if (user != null && user.city != null) {
        setState(() {
          _cityController.text = user.city!;
        });
      }
    }
  }

  // ─── Save ───

  Future<void> _save() async {
    final epState = ref.read(editProfileProvider);
    final notifier = ref.read(editProfileProvider.notifier);

    final profileData = <String, dynamic>{
      'bio': _bioController.text.trim(),
      'city': _cityController.text.trim(),
      'gender_pref': epState.selectedGenderPref,
      'age_pref_min': epState.ageRange.start.round(),
      'age_pref_max': epState.ageRange.end.round(),
      'match_radius_km': epState.distanceKm.round(),
    };

    final detailsData = <String, dynamic>{
      'height': int.tryParse(_heightController.text),
      'weight': int.tryParse(_weightController.text),
      'zodiac': epState.selectedZodiac,
      'job': _jobController.text.trim(),
      'school': _schoolController.text.trim(),
      'smoking': epState.selectedSmoking,
      'alcohol': epState.selectedAlcohol,
      'pets': _petsController.text.trim(),
      'music_type': _musicController.text.trim(),
      'personality': _personalityController.text.trim(),
    };

    final success = await notifier.saveProfile(profileData, detailsData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? context.tr('save_success') : context.tr('save_error'),
          ),
        ),
      );

      if (success) {
        ref.read(navigationServiceProvider).pop();
      }
    }
  }

  // ─── Dropdown Helpers ───

  List<DropdownMenuItem<String>> _zodiacItems() {
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

  List<DropdownMenuItem<String>> _frequencyItems() {
    return [
      DropdownMenuItem(value: 'YES', child: Text(context.tr('freq_yes'))),
      DropdownMenuItem(value: 'NO', child: Text(context.tr('freq_no'))),
      DropdownMenuItem(value: 'SOMETIMES', child: Text(context.tr('freq_sometimes'))),
    ];
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final epState = ref.watch(editProfileProvider);

    return AppScaffold(
      title: context.tr('edit_profile'),
      showBackButton: true,
      padding: EdgeInsets.zero,
      bottomNavigationBar: _buildStickyButton(epState),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Question Nudge Banner ───
            Builder(builder: (_) {
              final user = ref.watch(userProvider).valueOrNull;
              if (user == null || user.questionCount >= AppConstants.minQuestions) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('question_nudge_edit_hint'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                        child: Text(context.tr('question_nudge_go_questions')),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // ─── Photos Section ───
            _sectionTitle(context.tr('photos')),
            const SizedBox(height: AppSpacing.sm),
            PhotoGridFull(
              photos: epState.photos,
              editMode: true,
              onSlotTap: _onPhotoSlotTap,
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ─── About Section ───
            _sectionTitle(context.tr('about')),
            const SizedBox(height: AppSpacing.sm),
            _buildBioField(),
            const SizedBox(height: AppSpacing.sectionGap),

            // ─── Basic Info Section ───
            _sectionTitle(context.tr('basic_info')),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _nameController,
              label: context.tr('name'),
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.itemGap),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _cityController,
                    label: context.tr('city'),
                    hint: context.tr('city_hint'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _locationButton(),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ─── Details Section ───
            _sectionTitle(context.tr('details')),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _heightController,
                    label: context.tr('height'),
                    hint: 'cm',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: AppSpacing.itemGap),
                Expanded(
                  child: AppTextField(
                    controller: _weightController,
                    label: context.tr('weight'),
                    hint: 'kg',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.itemGap),
            _buildDropdown(
              label: context.tr('zodiac'),
              value: epState.selectedZodiac,
              items: _zodiacItems(),
              onChanged: (v) => ref.read(editProfileProvider.notifier).setZodiac(v),
            ),
            const SizedBox(height: AppSpacing.itemGap),
            AppTextField(
              controller: _jobController,
              label: context.tr('job'),
              hint: context.tr('job_hint'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.itemGap),
            AppTextField(
              controller: _schoolController,
              label: context.tr('school'),
              hint: context.tr('school_hint'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.itemGap),
            _buildDropdown(
              label: context.tr('smoking'),
              value: epState.selectedSmoking,
              items: _frequencyItems(),
              onChanged: (v) => ref.read(editProfileProvider.notifier).setSmoking(v),
            ),
            const SizedBox(height: AppSpacing.itemGap),
            _buildDropdown(
              label: context.tr('alcohol'),
              value: epState.selectedAlcohol,
              items: _frequencyItems(),
              onChanged: (v) => ref.read(editProfileProvider.notifier).setAlcohol(v),
            ),
            const SizedBox(height: AppSpacing.itemGap),
            AppTextField(
              controller: _petsController,
              label: context.tr('pets'),
              hint: context.tr('pets_hint'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.itemGap),
            AppTextField(
              controller: _musicController,
              label: context.tr('music'),
              hint: context.tr('music_hint'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.itemGap),
            AppTextField(
              controller: _personalityController,
              label: context.tr('personality'),
              hint: context.tr('personality_hint'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ─── Preferences Section ───
            _sectionTitle(context.tr('preferences')),
            const SizedBox(height: AppSpacing.sm),
            _buildGenderPref(epState),
            const SizedBox(height: AppSpacing.lg),
            _buildAgeRange(epState),
            const SizedBox(height: AppSpacing.lg),
            _buildDistanceSlider(epState),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ───

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppTextField(
          controller: _bioController,
          label: context.tr('bio'),
          hint: context.tr('bio_hint'),
          maxLines: 4,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _locationButton() {
    final locState = ref.watch(locationProvider);

    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: locState.isLoading ? null : _updateLocation,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primarySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: locState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: AppLoadingWidget.small(),
              )
            : QIcon(QIcons.icMapPin, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
  }

  Widget _buildGenderPref(EditProfileState epState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('gender_preference'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            selectedBackgroundColor: AppColors.primarySurface,
            selectedForegroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeRange(EditProfileState epState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('age_range')}: ${epState.ageRange.start.round()} - ${epState.ageRange.end.round()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          activeColor: AppColors.primary,
          inactiveColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          onChanged: (values) => ref.read(editProfileProvider.notifier).setAgeRange(values),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider(EditProfileState epState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr('distance')}: ${epState.distanceKm.round()} km',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Slider(
          value: epState.distanceKm,
          min: 5,
          max: 200,
          divisions: 39,
          label: '${epState.distanceKm.round()} km',
          activeColor: AppColors.primary,
          inactiveColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          onChanged: (value) => ref.read(editProfileProvider.notifier).setDistanceKm(value),
        ),
      ],
    );
  }

  Widget _buildStickyButton(EditProfileState epState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: context.tr('save'),
          isLoading: epState.isSaving,
          fullWidth: true,
          onPressed: epState.isSaving ? null : _save,
        ),
      ),
    );
  }
}
