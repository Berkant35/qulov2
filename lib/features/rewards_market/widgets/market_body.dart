import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/empty_state_view.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/widgets/page_section_list.dart';
import 'package:qulo_v2/features/rewards_market/domain/market_catalog.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_brand_group.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_country_preview_chips.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_item_card.dart';

/// Vitrin gövdesi (spec §7.3): [önizleme çipleri] → bölümler → marka grupları | boş durum.
class MarketBody extends StatelessWidget {
  const MarketBody({
    super.key,
    required this.view,
    required this.previewCountry,
    required this.onCountrySelected,
    required this.onRefresh,
    required this.onItemTap,
    required this.onBannerShown,
    required this.onBannerTap,
    required this.onFeaturedShown,
    required this.onFeaturedTap,
  });

  final MarketView view;
  final String? previewCountry;
  final void Function(String? country) onCountrySelected;
  final Future<void> Function() onRefresh;
  final void Function(MarketItem item) onItemTap;
  final void Function(BannerItemView item, BannerCarouselSectionView section) onBannerShown;
  final void Function(BannerItemView item, BannerCarouselSectionView section) onBannerTap;
  final void Function(FeaturedItemView item, FeaturedItemsSectionView section) onFeaturedShown;
  final void Function(FeaturedItemView item, FeaturedItemsSectionView section) onFeaturedTap;

  @override
  Widget build(BuildContext context) {
    final groups = groupByBrand(view.items);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          if (view.previewCountries.isNotEmpty) ...[
            MarketCountryPreviewChips(
              countries: view.previewCountries,
              selected: previewCountry,
              onSelected: onCountrySelected,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          PageSectionList(
            sections: view.sections,
            featuredItemExtent: MarketItemCard.extentOf(context),
            featuredItemBuilder: (_, featured, section) => MarketItemCard(
              item: featured.item,
              onTap: () => onFeaturedTap(featured, section),
            ),
            onBannerShown: onBannerShown,
            onBannerTap: onBannerTap,
            onFeaturedShown: onFeaturedShown,
          ),
          if (groups.isEmpty)
            EmptyStateView(icon: const DiamondIcon.rainbow(size: 48), title: context.tr('market_empty'))
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, AppSpacing.md),
              child: Text(
                context.tr('market_catalog_title'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final group in groups)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: MarketBrandGroupView(group: group, onItemTap: onItemTap),
              ),
          ],
        ],
      ),
    );
  }
}
