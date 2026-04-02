import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/purchase_grid.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/diamonds/screens/diamonds_screen.dart';

mixin DiamondsScreenMixin on ConsumerState<DiamondsScreen> {
  List<DiamondTransaction> history = [];
  bool loadingHistory = false;
  bool purchasing = false;

  void initMixin() {
    Future.microtask(() {
      ref.read(diamondProvider.notifier).fetchBalance();
      ref.read(dailyStatsProvider.notifier).fetchStats();
      ref.read(referralProvider.notifier).fetchAll();
      loadHistory();

      final balance = ref.read(diamondProvider).valueOrNull;
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.diamondsScreenView,
        params: {
          if (balance != null)
            AnalyticsEvents.paramCurrentBalance: balance.purple,
        },
      );
    });
  }

  void disposeMixin() {
    // Reserved for future cleanup
  }

  Future<void> loadHistory() async {
    setState(() => loadingHistory = true);
    final result = await ref.read(diamondProvider.notifier).fetchHistory();
    if (mounted) {
      result.when(
        success: (response) => setState(() {
          history = response.items;
          loadingHistory = false;
        }),
        failure: (f) {
          dev.log('fetchHistory failed: $f', name: 'DiamondsScreen');
          setState(() => loadingHistory = false);
        },
      );
    }
  }

  void onViewPlans() {
    ref.read(navigationServiceProvider).go(RouteNames.subscription);
  }

  Future<void> onPurchase(PurchasePackage package) async {
    if (purchasing) return;
    setState(() => purchasing = true);

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.diamondsPurchaseStart,
      params: {
        AnalyticsEvents.paramProductId: package.tier.productId,
      },
    );

    try {
      final success = await ref
          .read(diamondProvider.notifier)
          .purchaseByProductId(package.tier.productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? context.tr('purchase_success')
                  : context.tr('purchase_failed'),
            ),
          ),
        );
        if (success) loadHistory();
      }
    } finally {
      if (mounted) setState(() => purchasing = false);
    }
  }

  void onSeeAllHistory() {
    // Deferred: Transaction history screen not yet implemented
  }
}
