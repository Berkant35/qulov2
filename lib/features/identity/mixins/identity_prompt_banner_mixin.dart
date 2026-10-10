import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/identity_analytics.dart';
import 'package:qulo_v2/core/services/one_time_flag_store.dart';
import 'package:qulo_v2/features/identity/identity_sheet_launcher.dart';
import 'package:qulo_v2/features/identity/widgets/identity_prompt_banner.dart';
import 'package:qulo_v2/providers/user_provider.dart';

mixin IdentityPromptBannerMixin on ConsumerState<IdentityPromptBanner> {
  static const _dismissedKeyPrefix = 'identity_prompt_dismissed';

  /// Kapatma durumu okunana kadar gizli: bayrak yüklenirken banner yanıp sönmez.
  bool dismissed = true;

  /// Bayrak kullanıcıya özel: aynı cihazda A'nın kapatması B'nin davetini gizlemez.
  String? _userId;

  String _dismissedKey(String userId) => '${_dismissedKeyPrefix}_$userId';

  void initBanner() {
    ref.listenManual(
      userProvider.select((u) => u.valueOrNull?.id),
      (_, id) => _load(id),
      fireImmediately: true,
    );
  }

  Future<void> _load(String? userId) async {
    _userId = userId;
    // Kullanıcı bilinmeden bayrak okunamaz: bilinene kadar (ya da çıkışta) gizli kalır.
    if (userId == null) {
      if (!dismissed) setState(() => dismissed = true);
      return;
    }
    final value = await OneTimeFlagStore.isSet(_dismissedKey(userId));
    if (!mounted || _userId != userId) return;
    setState(() => dismissed = value);
  }

  Future<void> dismiss() async {
    final userId = _userId;
    setState(() => dismissed = true);
    if (userId != null) await OneTimeFlagStore.mark(_dismissedKey(userId));
  }

  Future<void> add() async {
    final opened = await IdentitySheetLauncher.open(ref, entryPoint: IdentityEntryPoint.banner);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('error_general'))));
    }
  }
}
