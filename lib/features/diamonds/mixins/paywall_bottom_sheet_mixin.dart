import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/purchase_outcome.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/features/diamonds/models/diamond_tier.dart';
import 'package:qulo_v2/features/diamonds/widgets/celebration_dialog.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

/// [PaywallBottomSheetContent] logic'i: abonelik / elmas satın alma, geri yükleme, başlık.
///
/// Ücretli satın alma sheet kapansa da (401 çıkışı, deep link) tamamlanır: abonelik,
/// günlük haklar ve elmas tazelemesi KOŞULSUZ — kapsam await ÖNCESİ alınır. Eskiden
/// `if (!mounted) return;` tazelemeyi atlıyor, Plus hakları ve bakiye bayat kalıyordu.
/// Sheet'i kapatma, kutlama ve hata mesajı yalnız açık sheet'te.
mixin PaywallBottomSheetMixin on ConsumerState<PaywallBottomSheetContent> {
  bool isPurchasing = false;

  String titleForTrigger(BuildContext context) {
    return switch (widget.trigger) {
      'undo_locked' => context.tr('paywall_title_undo'),
      'passport_locked' => context.tr('paywall_title_passport'),
      'question_limit' => context.tr('paywall_title_questions'),
      'swipe_limit' => context.tr('paywall_title_swipes'),
      _ => context.tr('paywall_title_general'),
    };
  }

  bool get isPremiumOnlyTrigger => widget.trigger == 'passport_locked';

  Future<void> handlePurchase(String plan) async {
    if (isPurchasing) return;
    setState(() => isPurchasing = true);

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.subscriptionPurchaseStart,
      params: {
        AnalyticsEvents.paramTier: plan,
        AnalyticsEvents.paramTrigger: widget.trigger,
      },
    );

    final productId = plan == 'premium'
        ? RevenueCatService.premiumProductId
        : RevenueCatService.plusProductId;
    final container = ProviderScope.containerOf(context, listen: false);
    final nav = ref.read(navigationServiceProvider);
    final outcome = await ref
        .read(subscriptionProvider.notifier)
        .purchaseByProductId(productId);

    if (outcome == PurchaseOutcome.success) {
      container
        ..invalidate(subscriptionProvider)
        ..invalidate(dailyStatsProvider)
        ..invalidate(diamondProvider);
    }

    if (!mounted) return;

    if (outcome != PurchaseOutcome.success) {
      _endFailedPurchase(outcome);
      return;
    }

    Navigator.of(context).pop();

    final isPremium = plan == 'premium';
    final planName = isPremium
        ? context.tr('sub_plan_premium')
        : context.tr('sub_plan_plus');
    final config = ref.read(economyConfigProvider);
    final bonus = isPremium
        ? config.limitsFor('premium').monthlyPurpleBonus
        : config.limitsFor('plus').monthlyPurpleBonus;

    // Kök navigator: sheet kapandıktan sonra da güvenle açılır.
    unawaited(nav.showAppDialog<void>(
      CustomDialog(
        name: 'subscription_celebration',
        barrierDismissible: false,
        builder: (_) => CelebrationDialog(
          planName: planName,
          diamondBonus: bonus,
          isPremium: isPremium,
        ),
      ),
    ));
  }

  Future<void> handleConsumablePurchase(PurchasePackage package) async {
    if (isPurchasing) return;
    setState(() => isPurchasing = true);

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.diamondsPurchaseStart,
      params: {
        AnalyticsEvents.paramProductId: package.tier.productId,
        AnalyticsEvents.paramDiamondsAmount: package.amount,
        AnalyticsEvents.paramTrigger: widget.trigger,
      },
    );

    final container = ProviderScope.containerOf(context, listen: false);
    final outcome = await ref
        .read(diamondProvider.notifier)
        .purchaseByProductId(package.tier.productId);

    if (outcome == PurchaseOutcome.success) container.invalidate(diamondProvider);

    if (!mounted) return;

    if (outcome == PurchaseOutcome.success) {
      Navigator.of(context).pop();
    } else {
      _endFailedPurchase(outcome);
    }
  }

  /// Satın alma bitmedi: düğme yeniden açılır. Vazgeçmede (kullanıcı mağaza
  /// penceresini kapattı) mesaj YOK — eskiden "satın alma başarısız" çıkıyordu.
  void _endFailedPurchase(PurchaseOutcome outcome) {
    setState(() => isPurchasing = false);
    if (outcome == PurchaseOutcome.cancelled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('purchase_failed'))),
    );
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
