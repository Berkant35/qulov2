import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';

void main() {
  group('partitionProductIds', () {
    test('abonelikler ve tuketilebilirler ayrilir', () {
      final groups = RevenueCatService.partitionProductIds([
        'qulopurple50',
        RevenueCatService.plusProductId,
        'qulopurple6000',
        RevenueCatService.premiumProductId,
      ]);

      expect(groups.subscriptions, [
        RevenueCatService.plusProductId,
        RevenueCatService.premiumProductId,
      ]);
      expect(groups.consumables, ['qulopurple50', 'qulopurple6000']);
    });

    test(
      'tek kategori varken digeri bos kalir — bos kategori sorgulanmasin',
      () {
        final onlyConsumables = RevenueCatService.partitionProductIds([
          'qulopurple150',
        ]);
        expect(onlyConsumables.subscriptions, isEmpty);
        expect(onlyConsumables.consumables, ['qulopurple150']);

        final onlySubs = RevenueCatService.partitionProductIds([
          RevenueCatService.plusProductId,
        ]);
        expect(onlySubs.consumables, isEmpty);
        expect(onlySubs.subscriptions, [RevenueCatService.plusProductId]);
      },
    );

    test('bos girdi iki tarafta da bos', () {
      final groups = RevenueCatService.partitionProductIds(const []);
      expect(groups.subscriptions, isEmpty);
      expect(groups.consumables, isEmpty);
    });
  });

  test('abonelik kimlikleri magazadaki gercek urunlerdir', () {
    // Magaza kimlikleri dis sozlesme: degistirilirse App Store/Play tarafinda
    // dogrulanmadan gecmesin diye literal olarak sabitlendi.
    expect(RevenueCatService.plusProductId, 'quloplusmonthly2');
    expect(
      RevenueCatService.premiumProductIdFor(android: false),
      'qulopremiummonthly2',
    );
    // Iki magazanin da bilinen kimlikleri (kategori ayrimi icin); cihazda
    // sorgulanan liste subscriptionProductIdsForStore.
    expect(RevenueCatService.subscriptionProductIds, {
      'quloplusmonthly2',
      'qulopremiummonthly2',
      'qulopremiummonthly',
    });
    expect(RevenueCatService.subscriptionProductIdsForStore, [
      'quloplusmonthly2',
      RevenueCatService.premiumProductId,
    ]);
  });

  /// Play'deki Premium urunu `qulopremiummonthly` (2'siz) — App Store'daki `…2` degil.
  /// Tek sabit her iki magazada 2'li kimligi soruyordu; Play o urunu bilmedigi icin
  /// Android'de Premium fiyati "—", buton kapali, satin alma imkansizdi (2026-09-15).
  group('premium kimligi magazaya gore', () {
    test('Google Play: qulopremiummonthly', () {
      expect(
        RevenueCatService.premiumProductIdFor(android: true),
        'qulopremiummonthly',
      );
    });
    test('App Store: qulopremiummonthly2', () {
      expect(
        RevenueCatService.premiumProductIdFor(android: false),
        'qulopremiummonthly2',
      );
    });
    test('plus her iki magazada ayni kimlik', () {
      expect(RevenueCatService.plusProductId, 'quloplusmonthly2');
    });
    test('iki premium kimligi de abonelik kategorisine girer', () {
      final groups = RevenueCatService.partitionProductIds([
        'qulopremiummonthly',
        'qulopremiummonthly2',
        'qulopurple50',
      ]);
      expect(groups.subscriptions, [
        'qulopremiummonthly',
        'qulopremiummonthly2',
      ]);
      expect(groups.consumables, ['qulopurple50']);
    });
  });
}
