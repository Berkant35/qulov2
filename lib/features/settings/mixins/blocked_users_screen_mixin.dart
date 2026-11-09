import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/utils/block_flow.dart';
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
    // Depo await ONCESI alinir: dialog acikken ekran kapanirsa `ref` kullanilamaz,
    // onaylanan islem yine sunucuya gider.
    final blocks = ref.read(blockRepositoryProvider);
    final confirmed = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'unblock_user',
        title: context.tr('unblock_confirm_title'),
        message: context.tr('unblock_confirm_message'),
        confirmText: context.tr('unblock'),
        cancelText: context.tr('cancel'),
      ),
    );
    if (confirmed != true) return;
    // Liste her durumda sunucudan tazelenir (gercek durum); hata olursa
    // kullanici nedenini gorur — eskiden dokunus sessizce hicbir sey yapmiyordu.
    // Ekran kapandiysa tazelenecek liste de yok (saglayici autoDispose).
    void refreshList() {
      if (ref.context.mounted) ref.invalidate(listProvider);
    }

    await runServerAction(
      action: () => blocks.unblockUser(blockedId),
      onDone: refreshList,
      onFailed: (f) {
        refreshList();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(f.userMessageKey('unblock_failed')))),
        );
      },
    );
  }
}
