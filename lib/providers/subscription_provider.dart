import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// purchases_flutter 9+ kendi `SubscriptionInfo`unu export ediyor ve bizimkiyle
// (data/models/subscription_model.dart) cakisiyor. Buradaki her kullanim BIZIM
// modelimiz — SDK'ninkini gizliyoruz.
import 'package:purchases_flutter/purchases_flutter.dart' hide SubscriptionInfo;
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionInfo> {
  @override
  Future<SubscriptionInfo> build() async {
    return await fetchStatus();
  }

  Future<SubscriptionInfo> fetchStatus() async {
    try {
      final result = await ref.read(subscriptionRepositoryProvider).getStatus();
      final info = result.when(
        success: (data) => data,
        failure: (_) => SubscriptionInfo.free(),
      );
      AnalyticsManager.instance.setUserProperty(
        'subscription_tier',
        info.plan ?? 'free',
      );
      return info;
    } catch (_) {
      return SubscriptionInfo.free();
    }
  }

  Future<bool> purchasePackage(Package package) async {
    if (!RevenueCatService.isConfigured) {
      dev.log('RevenueCat not configured — cannot purchase subscription');
      return false;
    }
    try {
      final customerInfo = await RevenueCatService.purchasePackage(package);
      // Subscription transactions are managed by RevenueCat webhook;
      // pass active entitlement's latest purchase date as reference.
      final entitlement = customerInfo.entitlements.active.values
          .where((e) => e.productIdentifier == package.storeProduct.identifier)
          .firstOrNull;
      final txId = entitlement?.latestPurchaseDate;
      await _notifyBackend(package.storeProduct.identifier, txId);
      state = AsyncData(await fetchStatus());
      return true;
    } catch (e) {
      dev.log('Subscription purchase failed: $e');
      return false;
    }
  }

  Future<bool> purchaseByProductId(String productId) async {
    if (!RevenueCatService.isConfigured) {
      dev.log('RevenueCat not configured — cannot purchase subscription');
      return false;
    }
    try {
      final customerInfo = await RevenueCatService.purchaseByProductId(productId);
      // Subscription transactions are managed by RevenueCat webhook;
      // pass active entitlement's latest purchase date as reference.
      final entitlement = customerInfo.entitlements.active.values
          .where((e) => e.productIdentifier == productId)
          .firstOrNull;
      final txId = entitlement?.latestPurchaseDate;
      await _notifyBackend(productId, txId);
      state = AsyncData(await fetchStatus());
      return true;
    } catch (e) {
      dev.log('Subscription purchase failed: $e');
      return false;
    }
  }

  Future<void> _notifyBackend(String productId, [String? transactionId]) async {
    try {
      await ref.read(subscriptionRepositoryProvider).activate(productId, transactionId: transactionId);
    } catch (e) {
      dev.log('Backend notify error: $e');
    }
  }

  Future<void> restorePurchases() async {
    if (!RevenueCatService.isConfigured) return;
    try {
      await RevenueCatService.restorePurchases();
      state = AsyncData(await fetchStatus());
    } catch (e) {
      dev.log('restorePurchases error: $e');
    }
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionInfo>(
  SubscriptionNotifier.new,
);
