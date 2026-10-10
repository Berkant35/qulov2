import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/domain/market_catalog.dart';

MarketItem _i(String id, String brand, String country, num value) => MarketItem(
    id: id, brandKey: brand, countryCode: country, currency: 'X', faceValue: value, rainbowPrice: 1);

void main() {
  test('grup sırası sunucu sırasındaki ilk görünüm; grup içi ülke sonra kupür artan', () {
    final groups = groupByBrand([
      _i('a', 'GRAB', 'TH', 100),
      _i('b', 'DANA', 'ID', 10000),
      _i('c', 'GRAB', 'ID', 25000),
      _i('d', 'GRAB', 'TH', 50),
    ]);
    expect(groups.map((g) => g.brandKey), ['GRAB', 'DANA']);
    expect(groups.first.items.map((i) => i.id), ['c', 'd', 'a']);
  });

  test('boş katalog → boş liste', () => expect(groupByBrand(const []), isEmpty));
}
