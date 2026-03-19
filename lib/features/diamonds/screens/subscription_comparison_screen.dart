import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/diamonds/widgets/celebration_dialog.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/features/diamonds/models/plan_feature.dart';
import 'package:qulo_v2/features/diamonds/widgets/compact_plan_row.dart';
import 'package:qulo_v2/features/diamonds/widgets/subscription_plan_card.dart';

class SubscriptionComparisonScreen extends ConsumerStatefulWidget {
  const SubscriptionComparisonScreen({super.key});

  @override
  ConsumerState<SubscriptionComparisonScreen> createState() =>
      _SubscriptionComparisonScreenState();
}

class _SubscriptionComparisonScreenState
    extends ConsumerState<SubscriptionComparisonScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logEvent(AnalyticsEvents.subscriptionCompareView);
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);
    final currentPlan = subAsync.valueOrNull;
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('sub_choose_plan'),
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          children: [
            // Free plan — compact
            CompactPlanRow(
              name: context.tr('sub_plan_free'),
              price: context.tr('sub_price_free'),
              isCurrent: currentPlan?.isFree ?? true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Plus plan
            SubscriptionPlanCard(
              name: context.tr('sub_plan_plus'),
              price: context.tr('sub_price_plus'),
              features: [
                PlanFeature(QIcons.icCompass, context.tr('sub_plus_discovers')),
                PlanFeature(QIcons.icHelpCircle, context.tr('sub_plus_questions')),
                PlanFeature.widget(const DiamondIcon.purple(size: 16), context.tr('sub_plus_diamonds')),
                PlanFeature(QIcons.icSkipForward, context.tr('sub_plus_undos')),
                PlanFeature(QIcons.icEyeOff, context.tr('sub_plus_no_ads')),
              ],
              isRecommended: false,
              isCurrent: currentPlan?.isPlus ?? false,
              onSubscribe: () => _handlePurchase(context, 'plus'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Premium plan
            SubscriptionPlanCard(
              name: context.tr('sub_plan_premium'),
              price: context.tr('sub_price_premium'),
              features: [
                PlanFeature(QIcons.icCompass, context.tr('sub_premium_discovers')),
                PlanFeature(QIcons.icHelpCircle, context.tr('sub_premium_questions')),
                PlanFeature.widget(const DiamondIcon.purple(size: 16), context.tr('sub_premium_diamonds')),
                PlanFeature(QIcons.icSkipForward, context.tr('sub_premium_undos')),
                PlanFeature(QIcons.icGlobe, context.tr('sub_premium_passport')),
                PlanFeature(QIcons.icEyeOff, context.tr('sub_premium_no_ads')),
              ],
              isRecommended: true,
              isCurrent: currentPlan?.isPremium ?? false,
              onSubscribe: () => _handlePurchase(context, 'premium'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Restore purchases
            TextButton(
              onPressed: () => _handleRestore(context),
              child: Text(
                context.tr('sub_restore_purchases'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    String plan,
  ) async {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.subscriptionPurchaseStart,
      params: {AnalyticsEvents.paramTier: plan},
    );

    final productId = plan == 'premium' ? 'qulopremiummonthly' : 'quloplusmonthly2';
    final success = await ref
        .read(subscriptionProvider.notifier)
        .purchaseByProductId(productId);

    if (!context.mounted) return;

    if (success) {
      final isPremium = plan == 'premium';
      final planName = isPremium
          ? context.tr('sub_plan_premium')
          : context.tr('sub_plan_plus');
      final bonus = isPremium ? 1500 : 500;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CelebrationDialog(
          planName: planName,
          diamondBonus: bonus,
          isPremium: isPremium,
        ),
      );

      if (!context.mounted) return;

      // Invalidate providers so diamonds screen shows fresh data
      ref.invalidate(diamondProvider);
      ref.invalidate(subscriptionProvider);
      ref.invalidate(dailyStatsProvider);

      // Navigate to diamonds screen
      final nav = ref.read(navigationServiceProvider);
      nav.pop();
      nav.go(RouteNames.diamonds);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('purchase_failed'))),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('sub_restore_done'))),
      );
    }
  }
}

