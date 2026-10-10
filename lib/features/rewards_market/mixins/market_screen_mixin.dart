import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/providers/section_event_tracker.dart';
import 'package:qulo_v2/features/rewards_market/market_routes.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/features/rewards_market/refresh_failure_notice.dart';
import 'package:qulo_v2/features/rewards_market/screens/market_screen.dart';
import 'package:qulo_v2/features/rewards_market/widgets/market_item_sheet.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Vitrin ekranı davranışı: yükleme, önizleme ülkesi, ölçüm (GA4 + sunucu olayları), yönlendirme.
mixin MarketScreenMixin on ConsumerState<MarketScreen> {
  late final SectionEventTracker _tracker;
  AppLifecycleListener? _lifecycle;

  void initMixin() {
    _tracker = ref.read(sectionEventTrackerProvider)..attach();
    _lifecycle = AppLifecycleListener(onHide: _tracker.flush);
    Future.microtask(() async {
      await ref.read(marketProvider.notifier).load();
      if (!mounted) return;
      _logView();
    });
  }

  /// `market_view` yalnız başarılı yüklemeden sonra; ülke = önizleme ülkesi ya da katalogun ülkesi.
  void _logView() {
    final market = ref.read(marketProvider);
    final view = market.valueOrNull;
    if (market.hasError || view == null) return;
    AnalyticsManager.instance.logEvent(AnalyticsEvents.marketView, params: {
      AnalyticsEvents.paramCountry: previewCountry ?? view.items.firstOrNull?.countryCode ?? 'NONE',
    });
  }

  void disposeMixin() {
    _lifecycle?.dispose();
    unawaited(_tracker.detach());
  }

  String? get previewCountry => ref.read(marketProvider.notifier).previewCountry;

  Future<void> refresh() async {
    await ref.read(marketProvider.notifier).load(force: true);
    if (!mounted) return;
    showRefreshFailure(context, ref.read(marketProvider), 'market_load_failed');
  }

  void selectCountry(String? country) => ref.read(marketProvider.notifier).selectCountry(country);

  void openRedemptions() => ref.read(navigationServiceProvider).push(RouteNames.rewardsRedemptions);

  void onBannerShown(BannerItemView item, BannerCarouselSectionView section) {
    if (section.isDraft || !_tracker.impression(item.id)) return;
    AnalyticsManager.instance.logEvent(AnalyticsEvents.marketBannerImpression, params: {
      AnalyticsEvents.paramSectionId: section.id,
      AnalyticsEvents.paramItemId: item.id,
    });
  }

  void onFeaturedShown(FeaturedItemView item, FeaturedItemsSectionView section) {
    if (!section.isDraft) _tracker.impression(item.id);
  }

  /// Taslak (test admin önizlemesi) tıklamaları ölçülmez — gösterimlerle aynı kural.
  void onBannerTap(BannerItemView item, BannerCarouselSectionView section) {
    if (!section.isDraft) {
      _tracker.click(item.id);
      AnalyticsManager.instance.logEvent(AnalyticsEvents.marketBannerClick, params: {
        AnalyticsEvents.paramSectionId: section.id,
        AnalyticsEvents.paramItemId: item.id,
      });
    }
    switch (item.action) {
      case BannerCatalogAction(item: final product):
        // Kaynak kart = banner kartının kendisi (ölçüm: tıklama → itfa).
        openItem(product, sourceItemId: item.id);
      case BannerRouteAction(:final route):
        final name = bannerRouteName(route);
        if (name == RouteNames.rewardsRedemptions) {
          openRedemptions();
        } else if (name != null) {
          ref.read(navigationServiceProvider).go(name);
        }
      case BannerNoAction():
        break;
    }
  }

  void onFeaturedTap(FeaturedItemView item, FeaturedItemsSectionView section) {
    if (!section.isDraft) {
      _tracker.click(item.id);
      AnalyticsManager.instance.logEvent(AnalyticsEvents.marketFeaturedClick, params: {
        AnalyticsEvents.paramSectionId: section.id,
        AnalyticsEvents.paramItemId: item.id,
        AnalyticsEvents.paramBrandKey: item.item.brandKey,
      });
    }
    openItem(item.item, sourceItemId: item.id);
  }

  /// Ürün sayfası (spec §7.4). `sourceItemId` = itfayı başlatan bölüm kartı.
  void openItem(MarketItem item, {String? sourceItemId}) =>
      MarketItemSheet.show(ref, item: item, sourceItemId: sourceItemId);
}
