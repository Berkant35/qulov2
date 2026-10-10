import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/email_verification/email_verification_controller.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_error.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_outcome.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_session.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/features/rewards_market/providers/redeem_flow.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_item_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// `submit` başında (await'ten ÖNCE) yakalanan ekran bağımlılıkları — sayfa ağaçtan çıksa da geçerli.
typedef _SheetDeps = ({
  NavigationService navigation,
  ScaffoldMessengerState messenger,
  String Function(String key) tr,
});

/// Ürün sayfasının itfa davranışı: iş akışı [RedeemFlow]'da (GA4, tek uçuş, bakiye + market);
/// burada yalnız sonucun ekrana yansıması — satır içi hata, sayfayı kapatma, "Görüntüle" snackbar'ı.
///
/// Ağaçtan çıkmış sayfada yalnız `setState` ve `closeOverlay` atlanır (`closeOverlay` kök yığının
/// üstündeki rotayı kapatırdı); snackbar kök messenger'da yine gösterilir.
mixin MarketItemSheetMixin on ConsumerState<MarketItemSheet> {
  late final RedeemSession session = RedeemSession(itemId: widget.item.id, sourceItemId: widget.sourceItemId);
  RedeemError? error;

  bool get submitting => session.inFlight;

  Future<void> submit() async {
    if (session.inFlight) return;
    final _SheetDeps deps = (
      navigation: ref.read(navigationServiceProvider),
      messenger: ScaffoldMessenger.of(context),
      tr: context.l10n.get,
    );
    final pending = RedeemFlow(
      redeem: ref.read(rewardsRepositoryProvider).redeem,
      user: ref.read(userProvider.notifier),
      market: ref.read(marketProvider.notifier),
    ).submit(session, widget.item);
    setState(() => error = null);
    switch (await pending) {
      case RedeemIgnored():
        return;
      case RedeemInline(:final error) when error.kind == RedeemErrorKind.emailVerificationRequired:
        // Doğrulama sayfası ürün sayfasının üstünde açılır; doğrulanınca aynı anahtarla tekrar denenir.
        if (mounted) {
          await ref.read(emailVerificationControllerProvider).prompt(trigger: EmailVerifyTrigger.redeem);
        }
      case RedeemInline(:final error):
        if (mounted) setState(() => this.error = error);
      case RedeemClose(:final error, :final withView):
        final message = error == null ? deps.tr('market_redeem_success') : redeemErrorMessage(error, deps.tr);
        _closeWithSnack(deps, message, withView: withView);
    }
  }

  void _closeWithSnack(_SheetDeps deps, String message, {required bool withView}) {
    if (mounted) deps.navigation.closeOverlay();
    deps.messenger.showSnackBar(SnackBar(
      content: Text(message),
      action: withView
          ? SnackBarAction(
              label: deps.tr('market_redeem_view'),
              onPressed: () => deps.navigation.push(RouteNames.rewardsRedemptions),
            )
          : null,
    ));
  }
}
