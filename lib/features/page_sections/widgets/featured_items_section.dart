import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/widgets/section_heading.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Öne çıkan ürün şeridi; kart çizimi sayfaya özel `itemBuilder`'dan gelir (spec §7.2).
class FeaturedItemsSection extends StatelessWidget {
  const FeaturedItemsSection({
    super.key,
    required this.section,
    required this.itemBuilder,
    required this.itemExtent,
    this.onShown,
  });

  final FeaturedItemsSectionView section;
  final Widget Function(BuildContext context, FeaturedItemView item) itemBuilder;

  /// Kart yüksekliği (yatay liste sabit yükseklik ister).
  final double itemExtent;
  final void Function(FeaturedItemView item)? onShown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(heading: section.heading, isDraft: section.isDraft),
        SizedBox(
          height: itemExtent,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            itemCount: section.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final item = section.items[i];
              return VisibilityDetector(
                key: Key('featured_${section.id}_${item.id}'),
                // Kaydırarak tekrar %50 üzerine çıkınca `onShown` yeniden tetiklenir;
                // bu kasıtlı — tekilleştirme SectionEventTracker'da yapılır.
                onVisibilityChanged: (info) {
                  if (info.visibleFraction >= 0.5) onShown?.call(item);
                },
                child: itemBuilder(context, item),
              );
            },
          ),
        ),
      ],
    );
  }
}
