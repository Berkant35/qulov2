import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';

/// Mağazada ürün bulunamadı (RevenueCat `getProducts` boş döndü).
class PurchaseProductNotFoundException implements Exception {
  final String productId;
  const PurchaseProductNotFoundException(this.productId);

  @override
  String toString() => 'Product not found: $productId';
}

/// Satın alma sonucunun ölçümü — iOS ve Android aynı yoldan geçer
/// (`RevenueCatService`, iki mağaza da RevenueCat).
///
/// 2.0.17'ye kadar abonelik başarısı `diamonds_purchase_success` yazılıyordu
/// (`subscription_purchase_success` hiç atılmıyordu), vazgeçme gerçek hatayla
/// aynı olaydaydı ve `error_code` `e.toString()` idi (PlatformException metni).
/// Şimdi: abonelik / elmas ayrı olaylar, vazgeçme ayrı olay, `error_code` RevenueCat
/// kod adı (`storeProblemError` gibi).
abstract final class PurchaseAnalytics {
  static const String codeProductNotFound = 'product_not_found';
  static const String codeUnknown = 'unknown';

  static void logSuccess(String productId, {required bool isSubscription}) {
    AnalyticsManager.instance.logEvent(
      isSubscription
          ? AnalyticsEvents.subscriptionPurchaseSuccess
          : AnalyticsEvents.diamondsPurchaseSuccess,
      params: {AnalyticsEvents.paramProductId: productId},
    );
  }

  /// Vazgeçme (`purchaseCancelledError`) hata sayılmaz: ayrı `*_cancel` olayı.
  static void logFailure(
    String productId,
    Object error, {
    required bool isSubscription,
  }) {
    if (isCancellation(error)) {
      AnalyticsManager.instance.logEvent(
        isSubscription
            ? AnalyticsEvents.subscriptionPurchaseCancel
            : AnalyticsEvents.diamondsPurchaseCancel,
        params: {AnalyticsEvents.paramProductId: productId},
      );
      return;
    }
    AnalyticsManager.instance.logEvent(
      isSubscription
          ? AnalyticsEvents.subscriptionPurchaseFail
          : AnalyticsEvents.diamondsPurchaseFail,
      params: {
        AnalyticsEvents.paramProductId: productId,
        AnalyticsEvents.paramErrorCode: errorCodeOf(error),
      },
    );
  }

  /// Kullanıcı mağaza penceresini kapattı (RevenueCat `purchaseCancelledError`).
  static bool isCancellation(Object error) =>
      errorCodeOf(error) == PurchasesErrorCode.purchaseCancelledError.name;

  /// Hata → kısa, sabit kod adı (GA4 parametre sınırı ve gruplama için).
  static String errorCodeOf(Object error) {
    if (error is PlatformException) {
      try {
        return PurchasesErrorHelper.getErrorCode(error).name;
      } on FormatException {
        return codeUnknown;
      }
    }
    if (error is PurchaseProductNotFoundException) return codeProductNotFound;
    return codeUnknown;
  }
}
