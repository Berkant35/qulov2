import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/celebration_dialog.dart';
import 'package:qulo_v2/features/onboarding/widgets/paywall_comparison_table.dart';
import 'package:qulo_v2/features/onboarding/widgets/paywall_plan_button.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

class PremiumSuggestionSheet extends ConsumerWidget {
  const PremiumSuggestionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  AnalyticsManager.instance.logEvent(
                    AnalyticsEvents.onboardingV2PremiumDismissed,
                  );
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF666666)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Hero diamond
            const DiamondIcon.purple(size: 48, showGlow: true),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              context.tr('paywall_onboarding_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Comparison table
            const PaywallComparisonTable(),
            const SizedBox(height: AppSpacing.xl),

            // CTA buttons
            PaywallPlanButton(
              label: '${context.tr('sub_plan_premium')} · ${context.tr('sub_price_premium')}',
              isPrimary: true,
              onTap: () => _handlePurchase(context, ref, 'premium'),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            PaywallPlanButton(
              label: '${context.tr('sub_plan_plus')} · ${context.tr('sub_price_plus')}',
              isPrimary: false,
              onTap: () => _handlePurchase(context, ref, 'plus'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Maybe later
            GestureDetector(
              onTap: () {
                AnalyticsManager.instance.logEvent(
                  AnalyticsEvents.onboardingV2PremiumDismissed,
                );
                Navigator.of(context).pop();
              },
              child: Text(
                context.tr('paywall_maybe_later'),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    String plan,
  ) async {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.onboardingV2PremiumTapped,
    );
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.subscriptionPurchaseStart,
      params: {
        AnalyticsEvents.paramTier: plan,
        AnalyticsEvents.paramTrigger: 'onboarding',
      },
    );

    final productId =
        plan == 'premium' ? 'qulopremiummonthly2' : 'quloplusmonthly2';
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

      ref.invalidate(diamondProvider);
      ref.invalidate(subscriptionProvider);
      ref.invalidate(dailyStatsProvider);

      Navigator.of(context).pop(); // Close the sheet
    }
  }
}
