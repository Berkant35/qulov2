import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qulo_v2/core/config/env.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/meta_events_manager.dart';

class RevenueCatNotConfiguredException implements Exception {
  @override
  String toString() => 'RevenueCat is not configured. Please set API keys via --dart-define.';
}

class RevenueCatService {
  static bool _isConfigured = false;

  static bool get isConfigured => _isConfigured;

  static Future<void> init(String userId) async {
    final apiKey = Platform.isIOS
        ? Env.revenueCatAppleKey
        : Env.revenueCatGoogleKey;

    if (apiKey.isEmpty) return;

    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);
    _isConfigured = true;
    await _syncAdAttributionIds();
  }

  /// Meta Ads entegrasyonu için cihaz kimliklerini RevenueCat'e iletir
  /// ($idfa/$idfv/$gpsAdId + $fbAnonId). init() login akışında ATT
  /// prompt'undan sonra çağrıldığı için tek sefer yeterli.
  static Future<void> _syncAdAttributionIds() async {
    try {
      await Purchases.collectDeviceIdentifiers();
      final fbAnonId = await MetaEventsManager.instance.getAnonymousId();
      if (fbAnonId != null && fbAnonId.isNotEmpty) {
        await Purchases.setFBAnonymousID(fbAnonId);
      }
    } catch (e, st) {
      AnalyticsManager.instance.logNonFatalError(
        e,
        st,
        context: 'RevenueCatService._syncAdAttributionIds',
      );
    }
  }

  static void _ensureConfigured() {
    if (!_isConfigured) throw RevenueCatNotConfiguredException();
  }

  static Future<Offerings?> getOfferings() async {
    if (!_isConfigured) return null;
    return await Purchases.getOfferings();
  }

  static Future<CustomerInfo> purchasePackage(Package package) async {
    _ensureConfigured();
    try {
      // purchases_flutter 9+ ile `purchasePackage` deprecated; yeni API
      // PurchaseResult donuyor (customerInfo + storeTransaction).
      final result = await Purchases.purchase(PurchaseParams.package(package));
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.diamondsPurchaseSuccess,
        params: {AnalyticsEvents.paramProductId: package.storeProduct.identifier},
      );
      return result.customerInfo;
    } catch (e) {
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.diamondsPurchaseFail,
        params: {
          AnalyticsEvents.paramProductId: package.storeProduct.identifier,
          AnalyticsEvents.paramErrorCode: e.toString(),
        },
      );
      rethrow;
    }
  }

  static const plusProductId = 'quloplusmonthly2';
  static const premiumProductId = 'qulopremiummonthly2';
  static const _subscriptionIds = {plusProductId, premiumProductId};

  static Future<CustomerInfo> purchaseByProductId(String productId) async {
    _ensureConfigured();
    try {
      final category = _subscriptionIds.contains(productId)
          ? ProductCategory.subscription
          : ProductCategory.nonSubscription;
      final products = await Purchases.getProducts(
        [productId],
        productCategory: category,
      );
      if (products.isEmpty) {
        throw Exception('Product not found: $productId');
      }
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(products.first),
      );
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.diamondsPurchaseSuccess,
        params: {AnalyticsEvents.paramProductId: productId},
      );
      return result.customerInfo;
    } catch (e) {
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.diamondsPurchaseFail,
        params: {
          AnalyticsEvents.paramProductId: productId,
          AnalyticsEvents.paramErrorCode: e.toString(),
        },
      );
      rethrow;
    }
  }

  static Future<CustomerInfo> restorePurchases() async {
    _ensureConfigured();
    return await Purchases.restorePurchases();
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    _ensureConfigured();
    return await Purchases.getCustomerInfo();
  }

  static Future<void> logIn(String userId) async {
    if (!_isConfigured) return;
    await Purchases.logIn(userId);
  }

  static Future<void> logOut() async {
    if (!_isConfigured) return;
    await Purchases.logOut();
    _isConfigured = false;
  }
}
