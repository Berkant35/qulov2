import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/page_bar_indicator.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/mixins/banner_carousel_mixin.dart';
import 'package:qulo_v2/features/page_sections/widgets/banner_card.dart';
import 'package:qulo_v2/features/page_sections/widgets/section_heading.dart';
import 'package:visibility_detector/visibility_detector.dart';

class BannerCarouselSection extends StatefulWidget {
  const BannerCarouselSection({super.key, required this.section, required this.onShown, required this.onTap});

  final BannerCarouselSectionView section;
  final void Function(BannerItemView item) onShown;
  final void Function(BannerItemView item) onTap;

  @override
  State<BannerCarouselSection> createState() => _BannerCarouselSectionState();
}

class _BannerCarouselSectionState extends State<BannerCarouselSection> with BannerCarouselMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void didUpdateWidget(covariant BannerCarouselSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) onSectionUpdated(oldWidget.section);
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.section.items;
    return VisibilityDetector(
      key: Key('banner_carousel_${widget.section.id}'),
      onVisibilityChanged: onVisibilityChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(heading: widget.section.heading, isDraft: widget.section.isDraft),
          Listener(
            onPointerDown: onPointerDown,
            onPointerUp: onPointerUp,
            onPointerCancel: onPointerUp,
            child: AspectRatio(
              aspectRatio: 2,
              child: PageView.builder(
                controller: pageController,
                itemCount: items.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                  child: BannerCard(item: items[i], onTap: () => widget.onTap(items[i])),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl * 2),
            child: PageBarIndicator(
              count: items.length,
              current: currentPage,
              activeColor: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
