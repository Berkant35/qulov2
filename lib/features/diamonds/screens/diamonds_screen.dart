import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/diamonds/mixins/diamonds_screen_mixin.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamond_balance_card.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamonds_monthly_benefits_section.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamonds_referral_section.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamonds_transaction_history.dart';
import 'package:qulo_v2/features/diamonds/widgets/subscription_banner.dart';
import 'package:qulo_v2/features/diamonds/widgets/purchase_grid.dart';

class DiamondsScreen extends ConsumerStatefulWidget {
  const DiamondsScreen({super.key});

  @override
  ConsumerState<DiamondsScreen> createState() => _DiamondsScreenState();
}

class _DiamondsScreenState extends ConsumerState<DiamondsScreen>
    with DiamondsScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(diamondProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('diamonds'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            balance.when(
              data: (bal) => DiamondBalanceCard(
                greenCount: bal.green,
                purpleCount: bal.purple,
              ),
              loading: () => const Center(child: AppLoadingWidget.large()),
              error: (_, __) => Center(
                child: Text(
                  context.tr('failed_load_balance'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.error,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Exchange Center Button
            OutlinedButton.icon(
              onPressed: () {
                ref.read(navigationServiceProvider).go(RouteNames.exchange);
              },
              icon: QIcon(QIcons.icGem, size: 18, color: context.appColors.primary),
              label: Text(context.tr('exchange_title')),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appColors.primary,
                side: BorderSide(color: context.appColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            // Subscription Banner
            subAsync.when(
              data: (sub) => SubscriptionBanner(
                subscription: sub,
                onViewPlans: onViewPlans,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => SubscriptionBanner(
                subscription: SubscriptionInfo.free(),
                onViewPlans: onViewPlans,
              ),
            ),

            // Monthly Benefits
            const DiamondsMonthlyBenefitsSection(),

            const SizedBox(height: AppSpacing.sectionGap),

            // Referral
            const DiamondsReferralSection(),

            const SizedBox(height: AppSpacing.sectionGap),

            // Purchase Section Header
            Text(
              context.tr('purchase_purple'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Purchase Grid
            PurchaseGrid(
              onPurchase: onPurchase,
              isLoading: purchasing,
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            // Transaction History
            DiamondsTransactionHistory(
              history: history,
              isLoading: loadingHistory,
              onSeeAll: onSeeAllHistory,
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
