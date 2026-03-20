import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamond_balance_card.dart';
import 'package:qulo_v2/features/diamonds/widgets/monthly_benefits_card.dart';
import 'package:qulo_v2/features/diamonds/widgets/subscription_banner.dart';
import 'package:qulo_v2/features/diamonds/widgets/purchase_grid.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/features/diamonds/widgets/transaction_tile.dart';
import 'package:qulo_v2/core/widgets/referral_invite_card.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiamondsScreen extends ConsumerStatefulWidget {
  const DiamondsScreen({super.key});

  @override
  ConsumerState<DiamondsScreen> createState() => _DiamondsScreenState();
}

class _DiamondsScreenState extends ConsumerState<DiamondsScreen> {
  List<DiamondTransaction> _history = [];
  bool _loadingHistory = false;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(diamondProvider.notifier).fetchBalance();
      ref.read(dailyStatsProvider.notifier).fetchStats();
      ref.read(referralProvider.notifier).fetchAll();
      _loadHistory();

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

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final result = await ref.read(diamondProvider.notifier).fetchHistory();
    if (mounted) {
      result.when(
        success: (response) => setState(() {
          _history = response.items;
          _loadingHistory = false;
        }),
        failure: (f) {
          dev.log('fetchHistory failed: $f', name: 'DiamondsScreen');
          setState(() => _loadingHistory = false);
        },
      );
    }
  }

  void _onViewPlans() {
    ref.read(navigationServiceProvider).go(RouteNames.subscription);
  }

  Future<void> _onPurchase(PurchasePackage package) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);

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
        if (success) _loadHistory();
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  void _onSeeAllHistory() {
    // TODO: Navigate to full transaction history screen
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
            // 1. Balance Card
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

            // 2. Subscription Banner
            subAsync.when(
              data: (sub) => SubscriptionBanner(
                subscription: sub,
                onViewPlans: _onViewPlans,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => SubscriptionBanner(
                subscription: SubscriptionInfo.free(),
                onViewPlans: _onViewPlans,
              ),
            ),

            // ─── Monthly Benefits ───
            Builder(builder: (context) {
              final statsAsync = ref.watch(dailyStatsProvider);
              final subAsync = ref.watch(subscriptionProvider);
              return statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) {
                  final isFree = subAsync.valueOrNull?.isFree ?? true;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: MonthlyBenefitsCard(
                      stats: stats,
                      isFree: isFree,
                      onUpgrade: isFree
                          ? () => ref.read(navigationServiceProvider).go(RouteNames.subscription)
                          : null,
                    ),
                  );
                },
              );
            }),

            const SizedBox(height: AppSpacing.sectionGap),

            // Referral Invite Card
            Builder(builder: (context) {
              final referralAsync = ref.watch(referralProvider);
              return referralAsync.when(
                loading: () => const Center(child: AppLoadingWidget.small()),
                error: (_, __) => const SizedBox.shrink(),
                data: (referralState) => ReferralInviteCard(
                  code: referralState.code,
                  stats: referralState.stats,
                  onShare: () {
                    if (referralState.code != null) {
                      final code = referralState.code!;
                      final reward = ref.read(economyConfigProvider).rewards.referralPurple;
                      final message =
                          "Qulo'ya katıl! Davet kodumu kullan, ikimize de $reward mor elmas hediye: $code\nhttps://qulo.app/invite/$code";
                      ref.read(shareManagerProvider).share(message);
                    }
                  },
                ),
              );
            }),

            const SizedBox(height: AppSpacing.sectionGap),

            // 3. Purchase Section Header
            Text(
              context.tr('purchase_purple'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Purchase Grid
            PurchaseGrid(
              onPurchase: _onPurchase,
              isLoading: _purchasing,
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            // 5. Transaction History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('history'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_history.length > 5)
                  GestureDetector(
                    onTap: _onSeeAllHistory,
                    child: Text(
                      context.tr('see_all'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.appColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 6. Transaction History List (last 5)
            if (_loadingHistory)
              const Center(child: AppLoadingWidget.large())
            else if (_history.isEmpty)
              Text(
                context.tr('no_transactions'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              )
            else
              ..._history.take(5).map(
                    (tx) => TransactionTile(transaction: tx),
                  ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
