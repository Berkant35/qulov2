import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/rainbow_balance_chip.dart';
import 'package:qulo_v2/features/rewards_market/mixins/market_screen_mixin.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_body.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_error_view.dart';

/// Rainbow Market — Vitrin (spec §7.3).
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> with MarketScreenMixin {
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
    final market = ref.watch(marketProvider);
    final view = market.valueOrNull;
    return AppScaffold(
      title: context.tr('market_title'),
      padding: EdgeInsets.zero,
      isLoading: view == null && !market.hasError,
      actions: [
        if (view != null) RainbowBalanceChip(balance: view.balance),
        IconButton(
          tooltip: context.tr('market_my_gift_cards'),
          icon: const AppIcon(QIcons.gift),
          onPressed: openRedemptions,
        ),
      ],
      body: view == null
          ? MarketErrorView(error: market.error, onRetry: refresh)
          : MarketBody(
              view: view,
              previewCountry: previewCountry,
              onCountrySelected: selectCountry,
              onRefresh: refresh,
              onItemTap: openItem,
              onBannerShown: onBannerShown,
              onBannerTap: onBannerTap,
              onFeaturedShown: onFeaturedShown,
              onFeaturedTap: onFeaturedTap,
            ),
    );
  }
}
