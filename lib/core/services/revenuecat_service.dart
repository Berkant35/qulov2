import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qulo_v2/core/config/env.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';

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
      final info = await Purchases.purchasePackage(package);
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.diamondsPurchaseSuccess,
        params: {AnalyticsEvents.paramProductId: package.storeProduct.identifier},
      );
      return info;
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

  static const _subscriptionIds = {'quloplusmonthly2', 'qulopremiummonthly2'};

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
      final info = await Purchases.purchaseStoreProduct(products.first);
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.diamondsPurchaseSuccess,
        params: {AnalyticsEvents.paramProductId: productId},
      );
      return info;
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
