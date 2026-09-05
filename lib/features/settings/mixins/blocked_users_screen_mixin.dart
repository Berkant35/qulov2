import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// [BlockedUsersScreen] icin sunum-disi logic.
mixin BlockedUsersScreenMixin {
  /// Onay alindiysa engeli kaldirir ve listeyi tazeler.
  Future<void> confirmUnblock(
    BuildContext context,
    WidgetRef ref,
    String blockedId,
    ProviderBase<Object?> listProvider,
  ) async {
    final nav = ref.read(navigationServiceProvider);
    final confirmed = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'unblock_user',
        title: context.tr('unblock_user_title'),
        message: context.tr('unblock_user_message'),
        confirmText: context.tr('unblock'),
        cancelText: context.tr('cancel'),
      ),
    );
    if (confirmed != true) return;
    await ref.read(blockRepositoryProvider).unblockUser(blockedId);
    ref.invalidate(listProvider);
  }
}
