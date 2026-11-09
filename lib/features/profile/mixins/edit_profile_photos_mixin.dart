import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
///
/// Async-gap kurali: baslamis sunucu islemi (yukleme, silme, siralama) ekran
/// kapansa da tamamlanir ve duzenleme durumu tazelenir. Kapsam (container) await
/// ONCESI alinir, notifier'lar CAGRI ANINDA okunur: [editProfileProvider] her ekran
/// acilisinda yeniden tohumlanir — istek surerken ekran kapanip yeniden acildiysa
/// guncel durum tazelenir (onceden yakalanmis notifier eskimis olurdu). `context`
/// isteyen adimlar (sonraki sheet/dialog, hata snackbar'i) yalniz `mounted` iken.
mixin EditProfilePhotosMixin on EditProfileScreenMixin {
  // ─── Photo Actions ───

  void onPhotoSlotTap(int index) {
    final photos = ref.read(editProfileProvider).photos;
    final hasPhoto = photos[index] != null;

    if (hasPhoto) {
      _showExistingPhotoSheet(index);
    } else {
      _showPickPhotoSheet();
    }
  }

  Future<void> _showExistingPhotoSheet(int index) async {
    final result = await ref.read(navigationServiceProvider).showAppBottomSheet<String>(
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
    );
    if (!mounted) return;
    if (result == 'primary') {
      _makePrimary(index);
    } else if (result == 'delete') {
      _confirmDeletePhoto(index);
    }
  }

  Future<void> _showPickPhotoSheet() async {
    final result = await ref.read(navigationServiceProvider).showAppBottomSheet<String>(
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
    );
    if (!mounted) return;
    if (result == 'gallery') {
      _pickCropAndUpload(ImageSource.gallery);
    } else if (result == 'camera') {
      _pickCropAndUpload(ImageSource.camera);
    }
  }

  Future<void> _pickCropAndUpload(ImageSource source) async {
    final picker = ref.read(imagePickerManagerProvider);
    final picked = await pickWithPermissionPrompt(
      ref,
      context,
      () => picker.pickAndCrop(context, source),
    );
    if (picked == null || !mounted) return;

    final container = ProviderScope.containerOf(context, listen: false);
    // Yeni foto ilk bos slota oturur (sunucu sona ekler).
    final photos = ref.read(editProfileProvider).photos;
    final firstEmpty = photos.indexWhere((p) => p == null);
    final photoIndex = firstEmpty >= 0 ? firstEmpty : photos.length;

    final result = await container
        .read(userProvider.notifier)
        .uploadPhoto(picked.bytes, picked.mimeType);

    if (result.isSuccess) {
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.profilePhotoAdd,
        params: {
          AnalyticsEvents.paramPhotoIndex: photoIndex,
          AnalyticsEvents.paramSource:
              source == ImageSource.gallery ? 'gallery' : 'camera',
        },
      );
      _refreshPhotos(container);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('error_general'))),
      );
    }
  }

  Future<void> _makePrimary(int index) async {
    final photos = ref.read(editProfileProvider).photos;
    final currentPhotos = photos.whereType<String>().toList();
    if (index >= currentPhotos.length) return;

    final photo = currentPhotos.removeAt(index);
    currentPhotos.insert(0, photo);

    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(userProvider.notifier).reorderPhotos(currentPhotos);
    _refreshPhotos(container);
  }

  Future<void> _confirmDeletePhoto(int index) async {
    final container = ProviderScope.containerOf(context, listen: false);

    final confirmed = await ref.read(navigationServiceProvider).showAppDialog<bool>(
      ConfirmDialog(
        name: 'delete_photo_confirm',
        title: context.tr('delete_photo'),
        message: context.tr('delete_photo_confirm'),
        confirmText: context.tr('delete'),
        isDestructive: true,
      ),
    );
    if (confirmed != true) return;

    // Onaylanan silme ekran kapansa da sunucuya gider.
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.profilePhotoRemove,
      params: {AnalyticsEvents.paramPhotoIndex: index},
    );
    await container.read(userProvider.notifier).deletePhoto(index);
    _refreshPhotos(container);
  }

  /// Notifier cagri aninda okunur: ekran bu arada yeniden acildiysa guncel durum tazelenir.
  void _refreshPhotos(ProviderContainer container) =>
      container.read(editProfileProvider.notifier).refreshPhotos();
}
