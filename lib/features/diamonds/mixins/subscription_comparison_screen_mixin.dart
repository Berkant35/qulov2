import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/purchase_outcome.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/features/diamonds/screens/subscription_comparison_screen.dart';
import 'package:qulo_v2/features/diamonds/widgets/celebration_dialog.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// [SubscriptionComparisonScreen] logic'i: abonelik satın alma ve geri yükleme
/// (ekrandan taşındı — CLAUDE.md "Widget Logic → Mixin").
///
/// Vazgeçme (mağaza penceresi kapatıldı) sessiz: "satın alma başarısız" yalnız
/// gerçek hatada. Kutlamadaki aylık bonus sabit değil sunucu ekonomi ayarından
/// (paywall alt sayfasıyla aynı kaynak).
mixin SubscriptionComparisonScreenMixin on ConsumerState<SubscriptionComparisonScreen> {
  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.subscriptionCompareView);
  }

  Future<void> handlePurchase(String plan) async {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.subscriptionPurchaseStart,
      params: {AnalyticsEvents.paramTier: plan},
    );

    final nav = ref.read(navigationServiceProvider);
    final isPremium = plan == 'premium';
    final productId = isPremium
        ? RevenueCatService.premiumProductId
        : RevenueCatService.plusProductId;
    final outcome = await ref
        .read(subscriptionProvider.notifier)
        .purchaseByProductId(productId);

    if (!mounted || outcome == PurchaseOutcome.cancelled) return;

    if (outcome == PurchaseOutcome.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('purchase_failed'))),
      );
      return;
    }

    final planName = context.tr(isPremium ? 'sub_plan_premium' : 'sub_plan_plus');
    final bonus = ref
        .read(economyConfigProvider)
        .limitsFor(isPremium ? 'premium' : 'plus')
        .monthlyPurpleBonus;

    await nav.showAppDialog<void>(
      CustomDialog(
        name: 'subscription_celebration',
        barrierDismissible: false,
        builder: (_) => CelebrationDialog(
          planName: planName,
          diamondBonus: bonus,
          isPremium: isPremium,
        ),
      ),
    );

    if (!mounted) return;

    // Elmaslar ekranı taze veriyi göstersin.
    ref
      ..invalidate(diamondProvider)
      ..invalidate(subscriptionProvider)
      ..invalidate(dailyStatsProvider);

    nav.pop();
    nav.go(RouteNames.diamonds);
  }

  Future<void> handleRestore() async {
    await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('sub_restore_done'))),
      );
    }
  }
}
