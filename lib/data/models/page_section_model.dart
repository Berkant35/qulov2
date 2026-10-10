import 'package:equatable/equatable.dart';
import 'package:qulo_v2/data/models/json_read.dart';
import 'package:qulo_v2/data/models/market_item_model.dart';

/// Banner butonunun hedefi (spec §5.2). Bilinmeyen tür / eksik hedef → [BannerNoAction].
sealed class BannerAction extends Equatable {
  const BannerAction();

  static BannerAction fromJson(Object? json) {
    final map = jsonMap(json);
    switch (map?['type']) {
      case 'catalog_item':
        final itemJson = jsonMap(map!['catalog_item']);
        final item = itemJson == null ? null : MarketItem.tryParse(itemJson);
        return item == null ? const BannerNoAction() : BannerCatalogAction(item);
      case 'app_route':
        final route = jsonText(map!['route']);
        return route == null ? const BannerNoAction() : BannerRouteAction(route);
      default:
        return const BannerNoAction();
    }
  }
}

final class BannerNoAction extends BannerAction {
  const BannerNoAction();
  @override
  List<Object?> get props => const [];
}

final class BannerCatalogAction extends BannerAction {
  const BannerCatalogAction(this.item);
  final MarketItem item;
  @override
  List<Object?> get props => [item];
}

final class BannerRouteAction extends BannerAction {
  const BannerRouteAction(this.route);
  final String route;
  @override
  List<Object?> get props => [route];
}

class BannerItemView extends Equatable {
  const BannerItemView({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.action = const BannerNoAction(),
  });

  final String id;
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final BannerAction action;

  /// Kimlik, görsel ya da başlık yoksa kart çizilemez → null.
  static BannerItemView? tryParse(Map<String, dynamic> json) {
    final id = jsonText(json['id']);
    final imageUrl = jsonText(json['image_url']);
    final title = jsonText(json['title']);
    if (id == null || imageUrl == null || title == null) return null;
    return BannerItemView(
      id: id,
      imageUrl: imageUrl,
      title: title,
      subtitle: jsonText(json['subtitle']),
      ctaLabel: jsonText(json['cta_label']),
      action: BannerAction.fromJson(json['action']),
    );
  }

  @override
  List<Object?> get props => [id, imageUrl, title, subtitle, ctaLabel, action];
}

class FeaturedItemView extends Equatable {
  const FeaturedItemView({required this.id, required this.item});

  final String id;
  final MarketItem item;

  static FeaturedItemView? tryParse(Map<String, dynamic> json) {
    final id = jsonText(json['id']);
    final itemJson = jsonMap(json['catalog_item']);
    final item = itemJson == null ? null : MarketItem.tryParse(itemJson);
    if (id == null || item == null) return null;
    return FeaturedItemView(id: id, item: item);
  }

  @override
  List<Object?> get props => [id, item];
}

/// Sayfa bölümü (spec §5.2). Bilinmeyen tür ya da kartsız bölüm istemcide atlanır: sunucu yeni tür
/// eklediğinde eski sürüm kırılmaz.
sealed class PageSectionView extends Equatable {
  const PageSectionView({required this.id, required this.heading, required this.isDraft});

  final String id;
  final String? heading;

  /// Yalnız test admin yanıtında true (uygulamada "TASLAK" rozeti).
  final bool isDraft;

  static PageSectionView? tryParse(Map<String, dynamic> json) {
    final id = jsonText(json['id']);
    if (id == null) return null;
    final heading = jsonText(json['heading']);
    final isDraft = json['is_draft'] == true;
    switch (json['type']) {
      case 'banner_carousel':
        final items = jsonMaps(json['items']).map(BannerItemView.tryParse).whereType<BannerItemView>().toList();
        if (items.isEmpty) return null;
        return BannerCarouselSectionView(
          id: id,
          heading: heading,
          isDraft: isDraft,
          autoplaySeconds: jsonInt(json['autoplay_seconds'], 5),
          items: items,
        );
      case 'featured_items':
        final items = jsonMaps(json['items']).map(FeaturedItemView.tryParse).whereType<FeaturedItemView>().toList();
        if (items.isEmpty) return null;
        return FeaturedItemsSectionView(id: id, heading: heading, isDraft: isDraft, items: items);
      default:
        return null;
    }
  }
}

final class BannerCarouselSectionView extends PageSectionView {
  const BannerCarouselSectionView({
    required super.id,
    required super.heading,
    required super.isDraft,
    required this.autoplaySeconds,
    required this.items,
  });

  /// 0 = otomatik kayma yok.
  final int autoplaySeconds;
  final List<BannerItemView> items;

  @override
  List<Object?> get props => [id, heading, isDraft, autoplaySeconds, items];
}

final class FeaturedItemsSectionView extends PageSectionView {
  const FeaturedItemsSectionView({
    required super.id,
    required super.heading,
    required super.isDraft,
    required this.items,
  });

  final List<FeaturedItemView> items;

  @override
  List<Object?> get props => [id, heading, isDraft, items];
}
