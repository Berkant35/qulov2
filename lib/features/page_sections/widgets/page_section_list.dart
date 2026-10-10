import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/widgets/banner_carousel_section.dart';
import 'package:qulo_v2/features/page_sections/widgets/featured_items_section.dart';

/// Bölüm listesi → türe göre çizici (sunucu sırası korunur). Sayfaya özel her şey dışarıdan gelir.
class PageSectionList extends StatelessWidget {
  const PageSectionList({
    super.key,
    required this.sections,
    required this.featuredItemBuilder,
    required this.featuredItemExtent,
    required this.onBannerShown,
    required this.onBannerTap,
    this.onFeaturedShown,
  });

  final List<PageSectionView> sections;
  /// Kartın bölümü de verilir: aynı ürün iki bölümde olabilir — tıklama ölçümü kartın kendi
  /// bölümüne yazılır (ürün üzerinden bölüm aramak ilk eşleşeni bulurdu).
  final Widget Function(BuildContext context, FeaturedItemView item, FeaturedItemsSectionView section)
      featuredItemBuilder;
  final double featuredItemExtent;
  final void Function(BannerItemView item, BannerCarouselSectionView section) onBannerShown;
  final void Function(BannerItemView item, BannerCarouselSectionView section) onBannerTap;
  final void Function(FeaturedItemView item, FeaturedItemsSectionView section)? onFeaturedShown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          Padding(
            key: ValueKey(section.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
            child: switch (section) {
              BannerCarouselSectionView s => BannerCarouselSection(
                  section: s,
                  onShown: (item) => onBannerShown(item, s),
                  onTap: (item) => onBannerTap(item, s),
                ),
              FeaturedItemsSectionView s => FeaturedItemsSection(
                  section: s,
                  itemBuilder: (context, item) => featuredItemBuilder(context, item, s),
                  itemExtent: featuredItemExtent,
                  onShown: onFeaturedShown == null ? null : (item) => onFeaturedShown!(item, s),
                ),
            },
          ),
      ],
    );
  }
}
