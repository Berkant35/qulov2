import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/purchase_outcome.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

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
    if (result is Success) {
      await fetchBalance();
    }
    return result;
  }

  /// Vazgeçme [PurchaseOutcome.cancelled]: çağıran hata mesajı göstermez.
  Future<PurchaseOutcome> purchaseByProductId(String productId) async {
    if (!RevenueCatService.isConfigured) {
      dev.log('RevenueCat not configured — cannot purchase');
      return PurchaseOutcome.failed;
    }
    try {
      final customerInfo = await RevenueCatService.purchaseByProductId(productId);
      final txId = customerInfo.nonSubscriptionTransactions
          .where((t) => t.productIdentifier == productId)
          .lastOrNull
          ?.transactionIdentifier;
      await confirmPurchase(productId, transactionId: txId);
      return PurchaseOutcome.success;
    } catch (e) {
      dev.log('Diamond purchase failed: $e');
      return PurchaseOutcome.fromError(e);
    }
  }

  /// Mağaza ödemesi bitti: sunucuya bildir (kredi bu çağrıda yazılır), sonra cüzdanı tazele.
  Future<void> confirmPurchase(String productId, {String? transactionId}) async {
    await _notifyBackend(productId, transactionId);
    await syncWallet();
  }

  /// Sunucunun bakiyeyi değiştirdiği satın almalardan sonra İKİ bakiye aynasını tazeler:
  /// bu provider (Elmaslar ekranı, güç sayfası) ve `userProvider` (quiz / sohbet sorusu
  /// AppBar'ı `CompactDiamondBalance`, koç notu). Yalnız birini tazelemek AppBar'ı açılıştaki
  /// bakiyede bırakıyordu (2.0.18: Premium sonrası mor elmaslar soru ekranında güncellenmedi).
  ///
  /// `ref.invalidate(diamondProvider)` bunun yerine KULLANILMAZ — `build()` sabit 0 döner.
  Future<void> syncWallet() async {
    await fetchBalance();
    await ref.read(userProvider.notifier).fetchMe();
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
