import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionInfo> {
  @override
  Future<SubscriptionInfo> build() async {
    return await fetchStatus();
  }

  Future<SubscriptionInfo> fetchStatus() async {
    try {
      final result = await ref.read(subscriptionRepositoryProvider).getStatus();
      return result.when(
        success: (data) => data,
        failure: (_) => SubscriptionInfo.free(),
      );
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
      final txId = customerInfo.originalAppUserId;
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
      final txId = customerInfo.originalAppUserId;
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
