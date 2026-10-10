import 'package:equatable/equatable.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';

class MarketBrandGroup extends Equatable {
  const MarketBrandGroup(this.brandKey, this.items);

  final String brandKey;
  final List<MarketItem> items;

  @override
  List<Object?> get props => [brandKey, items];
}

/// Katalog → marka grupları. Grup sırası sunucu sırasındaki ilk görünüm (sunucu `sort_order`'ı korunur);
/// grup içi ülke kodu, sonra kupür artan ("Tümü" önizlemesinde farklı para birimleri karışmasın).
List<MarketBrandGroup> groupByBrand(List<MarketItem> items) {
  final byBrand = <String, List<MarketItem>>{};
  for (final item in items) {
    (byBrand[item.brandKey] ??= []).add(item);
  }
  return [
    for (final entry in byBrand.entries)
      MarketBrandGroup(
        entry.key,
        [...entry.value]..sort((a, b) {
            final byCountry = a.countryCode.compareTo(b.countryCode);
            return byCountry != 0 ? byCountry : a.faceValue.compareTo(b.faceValue);
          }),
      ),
  ];
}
