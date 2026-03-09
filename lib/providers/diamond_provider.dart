import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiamondNotifier extends AsyncNotifier<DiamondBalance> {
  @override
  Future<DiamondBalance> build() async {
    return const DiamondBalance(green: 0, purple: 0);
  }

  Future<void> fetchBalance() async {
    state = const AsyncLoading();
    final result = await ref.read(diamondRepositoryProvider).getBalance();
    state = result.when(
      success: (data) {
        AnalyticsManager.instance.setUserProperty(
          'diamond_balance',
          AnalyticsManager.diamondRange(data.purple + data.green),
        );
        return AsyncData(data);
      },
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<Result<DiamondHistoryResponse>> fetchHistory({int page = 1}) async {
    return ref.read(diamondRepositoryProvider).getHistory(page: page);
  }

  Future<Result<void>> purchase(String productId) async {
    final result = await ref.read(diamondRepositoryProvider).purchase(productId);
    result.when(success: (_) => fetchBalance(), failure: (_) {});
    return result;
  }

  Future<bool> purchaseConsumable(Package package) async {
    if (!RevenueCatService.isConfigured) {
      dev.log('RevenueCat not configured — cannot purchase');
      return false;
    }
    try {
      await RevenueCatService.purchasePackage(package);
      await _notifyBackend(package.storeProduct.identifier);
      await fetchBalance();
      return true;
    } catch (e) {
      dev.log('purchaseConsumable error: $e');
      return false;
    }
  }

  Future<bool> purchaseByProductId(String productId) async {
    if (!RevenueCatService.isConfigured) {
      dev.log('RevenueCat not configured — cannot purchase');
      return false;
    }
    try {
      final customerInfo = await RevenueCatService.purchaseByProductId(productId);
      final txId = customerInfo.originalAppUserId;
      await _notifyBackend(productId, txId);
      await fetchBalance();
      return true;
    } catch (e) {
      dev.log('Diamond purchase failed: $e');
      return false;
    }
  }

  Future<void> _notifyBackend(String productId, [String? transactionId]) async {
    try {
      await ref.read(diamondRepositoryProvider).purchase(productId, transactionId: transactionId);
    } catch (e) {
      dev.log('Backend notify error: $e');
    }
  }
}

final diamondProvider = AsyncNotifierProvider<DiamondNotifier, DiamondBalance>(DiamondNotifier.new);
