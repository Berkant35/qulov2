import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qulo_v2/core/config/env.dart';

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
    return await Purchases.purchasePackage(package);
  }

  static Future<CustomerInfo> purchaseByProductId(String productId) async {
    _ensureConfigured();
    final products = await Purchases.getProducts([productId]);
    if (products.isEmpty) {
      throw Exception('Product not found: $productId');
    }
    return await Purchases.purchaseStoreProduct(products.first);
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
