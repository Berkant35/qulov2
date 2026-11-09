import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/features/diamonds/mixins/subscription_comparison_screen_mixin.dart';
import 'package:qulo_v2/features/diamonds/models/plan_feature.dart';
import 'package:qulo_v2/features/diamonds/utils/monthly_price_label.dart';
import 'package:qulo_v2/features/diamonds/widgets/compact_plan_row.dart';
import 'package:qulo_v2/features/diamonds/widgets/subscription_plan_card.dart';
import 'package:qulo_v2/features/diamonds/widgets/subscription_legal_links.dart';

class SubscriptionComparisonScreen extends ConsumerStatefulWidget {
  const SubscriptionComparisonScreen({super.key});

  @override
  ConsumerState<SubscriptionComparisonScreen> createState() =>
      _SubscriptionComparisonScreenState();
}

class _SubscriptionComparisonScreenState
    extends ConsumerState<SubscriptionComparisonScreen>
    with SubscriptionComparisonScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);
    final currentPlan = subAsync.valueOrNull;
    final theme = Theme.of(context);
    final planPrices = watchPlanPriceLabels(context, ref);
    final plusPrice = planPrices.plus;
    final premiumPrice = planPrices.premium;

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
              price: plusPrice ?? unknownPriceLabel,
              features: [
                PlanFeature(QIcons.icCompass, context.tr('sub_plus_discovers')),
                PlanFeature(QIcons.helpCircle.outlined, context.tr('sub_plus_questions')),
                PlanFeature.widget(const DiamondIcon.purple(size: 16), context.tr('sub_plus_diamonds')),
                PlanFeature(QIcons.icSkipForward, context.tr('sub_plus_undos')),
                PlanFeature(QIcons.icEyeOff, context.tr('sub_plus_no_ads')),
              ],
              isRecommended: false,
              isCurrent: currentPlan?.isPlus ?? false,
              onSubscribe: plusPrice == null ? null : () => handlePurchase('plus'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Premium plan
            SubscriptionPlanCard(
              name: context.tr('sub_plan_premium'),
              price: premiumPrice ?? unknownPriceLabel,
              features: [
                PlanFeature(QIcons.icCompass, context.tr('sub_premium_discovers')),
                PlanFeature(QIcons.helpCircle.outlined, context.tr('sub_premium_questions')),
                PlanFeature.widget(const DiamondIcon.purple(size: 16), context.tr('sub_premium_diamonds')),
                PlanFeature(QIcons.icSkipForward, context.tr('sub_premium_undos')),
                PlanFeature(QIcons.globe.outlined, context.tr('sub_premium_passport')),
                PlanFeature(QIcons.icEyeOff, context.tr('sub_premium_no_ads')),
              ],
              isRecommended: true,
              isCurrent: currentPlan?.isPremium ?? false,
              onSubscribe: premiumPrice == null ? null : () => handlePurchase('premium'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Restore purchases
            TextButton(
              onPressed: handleRestore,
              child: Text(
                context.tr('sub_restore_purchases'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Terms of Use & Privacy Policy
            const SubscriptionLegalLinks(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
