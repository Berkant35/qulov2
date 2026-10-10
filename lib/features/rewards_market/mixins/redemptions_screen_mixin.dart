import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/rewards_market/providers/redemptions_provider.dart';
import 'package:qulo_v2/features/rewards_market/refresh_failure_notice.dart';
import 'package:qulo_v2/features/rewards_market/screens/redemptions_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// "Hediye kartlarım" ekranı davranışı: sayfalama, kod kopyalama, harici link açma.
mixin RedemptionsScreenMixin on ConsumerState<RedemptionsScreen> {
  final scrollController = ScrollController();

  void initMixin() => scrollController.addListener(_onScroll);

  void disposeMixin() => scrollController.dispose();

  Future<void> refresh() async {
    await ref.read(redemptionsProvider.notifier).refresh();
    if (!mounted) return;
    showRefreshFailure(context, ref.read(redemptionsProvider), 'redemptions_load_failed');
  }

  void copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('redemption_code_copied'))));
  }

  void openLink(String url) => ref.read(urlLauncherManagerProvider).launch(url);

  void retryLoadMore() => ref.read(redemptionsProvider.notifier).retryLoadMore();

  /// Son %20'ye gelince sonraki sayfa; başarısız istek kaydırmayla tekrarlanmaz (notifier kapısı).
  void _onScroll() {
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      ref.read(redemptionsProvider.notifier).loadMore();
    }
  }
}
