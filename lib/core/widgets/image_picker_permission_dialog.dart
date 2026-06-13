import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
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
