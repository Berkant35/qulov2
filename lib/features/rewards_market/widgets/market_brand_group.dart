import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/domain/market_catalog.dart';
import 'package:qulo_v2/features/rewards_market/market_labels.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_item_card.dart';

/// Marka grubu başlığı + yatay kart şeridi (sınıf adı `MarketBrandGroupView`: domain'deki
/// `MarketBrandGroup` veri sınıfıyla çakışmasın).
class MarketBrandGroupView extends StatelessWidget {
  const MarketBrandGroupView({super.key, required this.group, required this.onItemTap});

  final MarketBrandGroup group;
  final void Function(MarketItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, AppSpacing.sm),
          child: Text(
            rewardBrandLabel(context, group.brandKey),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: MarketItemCard.extentOf(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            itemCount: group.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) => MarketItemCard(item: group.items[i], onTap: () => onItemTap(group.items[i])),
          ),
        ),
      ],
    );
  }
}
