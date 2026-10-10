import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/diamond_type.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';

const _half = ExchangeRatePower(name: 'HALF', baseCost: 10, greenCost: 30, purpleCost: 10);

void main() {
  group('powerPurchaseTypes', () {
    test('rainbow kapalıyken mor + yeşil', () {
      expect(powerPurchaseTypes(rainbowEnabled: false), [DiamondType.purple, DiamondType.green]);
    });

    test('rainbow açıkken üçüncü seçenek Rainbow', () {
      expect(powerPurchaseTypes(rainbowEnabled: true),
          [DiamondType.purple, DiamondType.green, DiamondType.rainbow]);
    });
  });

  group('powerPrice', () {
    test('mor fiyatı purpleCost × adet', () {
      expect(powerPrice(_half, DiamondType.purple, 3), 30);
    });

    test('yeşil fiyatı greenCost × adet', () {
      expect(powerPrice(_half, DiamondType.green, 3), 90);
    });

    test('Rainbow fiyatı yeşil fiyatıyla aynı (sunucu kuralı)', () {
      expect(powerPrice(_half, DiamondType.rainbow, 3), 90);
    });
  });

  group('classifyPowerPurchaseFailure', () {
    test('sunucu kodları', () {
      expect(classifyPowerPurchaseFailure('INSUFFICIENT_DIAMONDS'), PowerPurchaseFailureKind.insufficient);
      expect(classifyPowerPurchaseFailure('RAINBOW_NOT_AVAILABLE'), PowerPurchaseFailureKind.rainbowUnavailable);
      expect(classifyPowerPurchaseFailure('DIAMOND_COOLDOWN'), PowerPurchaseFailureKind.cooldown);
    });

    test('bilinmeyen ya da kodsuz hata → other', () {
      expect(classifyPowerPurchaseFailure('RATE_LIMITED'), PowerPurchaseFailureKind.other);
      expect(classifyPowerPurchaseFailure(null), PowerPurchaseFailureKind.other);
    });
  });
}
