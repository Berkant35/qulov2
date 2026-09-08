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

    test('tek kategori varken digeri bos kalir — bos kategori sorgulanmasin', () {
      final onlyConsumables =
          RevenueCatService.partitionProductIds(['qulopurple150']);
      expect(onlyConsumables.subscriptions, isEmpty);
      expect(onlyConsumables.consumables, ['qulopurple150']);

      final onlySubs =
          RevenueCatService.partitionProductIds([RevenueCatService.plusProductId]);
      expect(onlySubs.consumables, isEmpty);
      expect(onlySubs.subscriptions, [RevenueCatService.plusProductId]);
    });

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
    expect(RevenueCatService.premiumProductId, 'qulopremiummonthly2');
    expect(RevenueCatService.subscriptionProductIds,
        {'quloplusmonthly2', 'qulopremiummonthly2'});
  });
}
