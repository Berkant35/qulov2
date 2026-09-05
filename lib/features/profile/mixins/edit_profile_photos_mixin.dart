import 'package:flutter/material.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_screen_mixin.dart';

/// Foto ekleme/silme/sirala islemleri — bottom sheet secimi + kirp/yukle akisi.
mixin EditProfilePhotosMixin on EditProfileScreenMixin {
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
}
