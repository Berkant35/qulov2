import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/purchase_outcome.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionInfo> {
  @override
  Future<SubscriptionInfo> build() async {
    // Logout'ta invalidate edilirken alttaki ekranlar hala dinliyor; kimliksizken
    // aga cikma (token'siz istek → 401 → Crashlytics gurultusu).
    final authStatus = ref.watch(authProvider.select((s) => s.status));
    if (authStatus != AuthStatus.authenticated) return SubscriptionInfo.free();
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

  /// Vazgeçme [PurchaseOutcome.cancelled]: çağıran hata mesajı göstermez.
  Future<PurchaseOutcome> purchaseByProductId(String productId) async {
    if (!RevenueCatService.isConfigured) {
      dev.log('RevenueCat not configured — cannot purchase subscription');
      return PurchaseOutcome.failed;
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
      return PurchaseOutcome.success;
    } catch (e) {
      dev.log('Subscription purchase failed: $e');
      return PurchaseOutcome.fromError(e);
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
