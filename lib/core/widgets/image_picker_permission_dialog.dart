import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Shows a dialog explaining that camera or photo permission was denied and
/// offers to open the OS-level app settings so the user can re-enable it.
Future<void> showImagePickerPermissionDialog(
  WidgetRef ref,
  BuildContext context, {
  required bool isCamera,
}) async {
  final nav = ref.read(navigationServiceProvider);

  final titleKey =
      isCamera ? 'camera_permission_denied_title' : 'photo_permission_denied_title';
  final messageKey = isCamera
      ? 'camera_permission_denied_message'
      : 'photo_permission_denied_message';

  final confirmed = await nav.showAppDialog<bool>(
    ConfirmDialog(
      name: 'image_picker_permission_denied',
      title: context.tr(titleKey),
      message: context.tr(messageKey),
      confirmText: context.tr('open_settings'),
      cancelText: context.tr('cancel'),
    ),
  );

  if (confirmed == true) {
    await ref.read(imagePickerManagerProvider).openAppSettings();
  }
}

/// Secici cagrisini sarar: izin reddinde ayarlara yonlendiren dialog'u
/// gosterir ve `null` doner (kullanici vazgecmis gibi). TUM secici cagrilari
/// bundan gecmeli — elle yazilan catch unutulunca izin reddi ya genel "yukleme
/// hatasi" mesajina (profil kurulumu) ya da yakalanmayan istisnaya (soru
/// gorseli) donusuyordu; iOS reddden sonra bir daha sormadigi icin kullanici
/// ayarlara gidilmesi gerektigini hic ogrenemiyordu.
Future<PickedImage?> pickWithPermissionPrompt(
  WidgetRef ref,
  BuildContext context,
  Future<PickedImage?> Function() pick,
) async {
  try {
    return await pick();
  } on ImagePickerPermissionException catch (e) {
    if (context.mounted) {
      await showImagePickerPermissionDialog(ref, context, isCamera: e.isCamera);
    }
    return null;
  }
}
