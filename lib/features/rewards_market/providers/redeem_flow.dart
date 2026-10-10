import 'dart:async';

import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_error.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_outcome.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_session.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// İtfa akışının widget-dışı yarısı (spec §7.4): GA4, tek anahtar + tek uçuş gönderim
/// ([RedeemSession]), hata eşlemesi ve sonucun bakiye + market'e uygulanması.
///
/// Bağımlılıklar gönderimden ÖNCE verilir: sayfa istek sürerken kapansa da sonuç YİNE uygulanır —
/// bakiye bayat-yüksek kalırsa yeniden açılan sayfa yeni anahtarla ikinci bir gerçek itfa başlatabilir.
/// Arka plan yenilemeleri (`load(force: true)`, `fetchMe`) beklenmez; hatalarını notifier'lar state'e
/// yazar, zone'a sızmaz (bkz. redeem_flow_test.dart — düz `test` + `runZonedGuarded`).
class RedeemFlow {
  const RedeemFlow({required this.redeem, required this.user, required this.market});

  final RedeemCall redeem;
  final UserNotifier user;
  final MarketNotifier market;

  /// Senkron kısım (GA4 başlangıç + `session.inFlight = true`) dönmeden önce çalışır.
  Future<RedeemOutcome> submit(RedeemSession session, MarketItem item) async {
    if (session.inFlight) return const RedeemIgnored();
    final params = <String, Object>{
      AnalyticsEvents.paramItemId: item.id,
      AnalyticsEvents.paramBrandKey: item.brandKey,
      AnalyticsEvents.paramCountry: item.countryCode,
    };
    AnalyticsManager.instance.logEvent(AnalyticsEvents.marketRedeemStart, params: params);
    return switch (await session.submit(redeem)) {
      null => const RedeemIgnored(),
      Success(:final data) => _onSuccess(data, item.rainbowPrice, params),
      Failure(:final failure) => _onFailure(classifyRedeemFailure(failure), params),
    };
  }

  RedeemOutcome _onSuccess(RedeemResult result, int price, Map<String, Object> params) {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.marketRedeemSuccess, params: params);
    user.applyRainbow(result.balance);
    market.applyRedeem(balance: result.balance, price: price);
    _reloadMarket();
    return const RedeemClose(withView: true);
  }

  RedeemOutcome _onFailure(RedeemError error, Map<String, Object> params) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.marketRedeemError,
      params: {...params, AnalyticsEvents.paramErrorCode: error.code},
    );
    switch (error.kind) {
      case RedeemErrorKind.itemUnavailable:
        _reloadMarket();
        return RedeemClose(error: error);
      case RedeemErrorKind.notAvailable:
        unawaited(user.fetchMe());
        _reloadMarket();
        return RedeemClose(error: error);
      case RedeemErrorKind.processing:
        _reloadMarket();
        return RedeemClose(error: error, withView: true);
      case RedeemErrorKind.insufficient:
        // Sunucu yetersiz dedi: yereldeki bakiye bayat — yenilenir, hata sayfada kalır.
        _reloadMarket();
        return RedeemInline(error);
      default:
        return RedeemInline(error);
    }
  }

  void _reloadMarket() => unawaited(market.load(force: true));
}
