import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';

/// Takas/guc satin alma yanitlari. Sozlesme qulo-server `exchange.service.ts`:
/// `convert` → `{purple_received, new_balance}`, `buyPower` → `{new_count,
/// new_balance}`, `getInventory` → `{inventory: [{power_name, count}]}`,
/// `getRates` → `{convert_ratio, powers: [{name, base_cost, green_cost,
/// purple_cost, accuracy_rate}]}`.
///
/// Canli sema (2026-09-11): `powers` ve `user_power_inventory`'de modelin
/// zorunlu okudugu kolonlarin hepsi NOT NULL; nullable olan tek alan
/// `powers.accuracy_rate` (numeric).
void main() {
  group('ConvertResponse / BuyPowerResponse', () {
    test('takas yaniti yeni bakiyeyle birlikte parse edilir', () {
      final r = ConvertResponse.fromJson({
        'purple_received': 10,
        'new_balance': {'green': 2, 'purple': 60},
      });

      expect(r.purpleReceived, 10);
      expect(r.newBalance.green, 2);
      expect(r.newBalance.purple, 60);
    });

    test('guc satin alma yaniti yeni sayac ve bakiyeyi tasir', () {
      final r = BuyPowerResponse.fromJson({
        'new_count': 3,
        'new_balance': {'green': 0, 'purple': 40},
      });

      expect(r.newCount, 3);
      expect(r.newBalance.purple, 40);
    });
  });

  group('InventoryResponse', () {
    test('envanter satirlari parse edilir', () {
      final r = InventoryResponse.fromJson({
        'inventory': [
          {'power_name': 'HINT', 'count': 2},
          {'power_name': 'HALF', 'count': 0},
        ],
      });

      expect(r.inventory.map((i) => (i.powerName, i.count)), [('HINT', 2), ('HALF', 0)]);
    });

    test('bos envanter basarili yanittir', () {
      expect(InventoryResponse.fromJson({'inventory': <dynamic>[]}).inventory, isEmpty);
    });
  });

  group('RatesResponse', () {
    Map<String, dynamic> power({Object? accuracy = 0.75, bool includeAccuracy = true}) => {
          'name': 'ORACLE',
          'base_cost': 30,
          'green_cost': 90,
          'purple_cost': 30,
          if (includeAccuracy) 'accuracy_rate': accuracy,
        };

    test('oran ve guc fiyatlari parse edilir', () {
      final r = RatesResponse.fromJson({
        'convert_ratio': 3,
        'powers': [power()],
      });

      expect(r.convertRatio, 3);
      final p = r.powers.single;
      expect((p.name, p.baseCost, p.greenCost, p.purpleCost), ('ORACLE', 30, 90, 30));
      expect(p.accuracyRate, 0.75);
    });

    test('accuracy_rate tam sayi gelirse double olur', () {
      // numeric kolon: PostgREST 1.0'i 1 olarak yazabilir.
      final p = RatesResponse.fromJson({'convert_ratio': 3, 'powers': [power(accuracy: 1)]})
          .powers
          .single;

      expect(p.accuracyRate, 1.0);
    });

    test('accuracy_rate null ya da eksikse null kalir — 0 sayilmaz', () {
      final nullValue = RatesResponse.fromJson({'convert_ratio': 3, 'powers': [power(accuracy: null)]});
      final missing = RatesResponse.fromJson({
        'convert_ratio': 3,
        'powers': [power(includeAccuracy: false)],
      });

      expect(nullValue.powers.single.accuracyRate, isNull);
      expect(missing.powers.single.accuracyRate, isNull);
    });
  });
}
