import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// `SettingsEmailNotificationsTile` logic'i (stateless widget → plain mixin).
mixin SettingsEmailNotificationsTileMixin {
  /// Tercih kaydedilemezse kullanici bunu gorur — anahtar yerinde kalir,
  /// sebebi (ag / genel hata) yerel dilde snackbar'da yazar.
  Future<void> onEmailNotificationsChanged(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final result = await ref.read(userProvider.notifier).setEmailNotifications(enabled);
    if (!context.mounted) return;
    result.when(
      success: (_) {},
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(f.userMessageKey('error_general'))),
          backgroundColor: context.appColors.error,
        ),
      ),
    );
  }
}
