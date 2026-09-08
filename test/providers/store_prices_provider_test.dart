import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/providers/store_prices_provider.dart';

/// Fiyat koda gomulu degil: magazadan gelir; magaza yoksa bos map (asla USD literal).
void main() {
  // REGRESYON (2026-09-08): fiyatlar `getOfferings()` ile okunuyordu. RevenueCat
  // panelinde tek offering vardi ve icinde SADECE abonelikler vardi; alti elmas
  // urunu hicbir offering'e ekli degildi. Sonuc: elmas kartlari sonsuza kadar
  // iskelet, Premium fiyati null oldugu icin paywall butonu KALICI disabled.
  // Fiyat artik satin almanin kullandigi ayni urun kimlikleriyle okunuyor.
  group('sorgulanan urun kimlikleri — magaza sozlesmesi', () {
    test('alti elmas urununun HEPSI fiyat sorgusuna dahil', () {
      expect(
        purchasableProductIds,
        containsAll([
          'qulopurple50',
          'qulopurple150',
          'qulopurple400',
          'qulopurple1000',
          'qulopurple2500',
          'qulopurple6000',
        ]),
      );
    });

    test('iki abonelik de dahil — Premium eksikse paywall butonu kilitlenir', () {
      expect(purchasableProductIds, contains(RevenueCatService.plusProductId));
      expect(purchasableProductIds, contains(RevenueCatService.premiumProductId));
    });

    test('satin alinabilen urun sayisi kadar kimlik sorulur, fazlasi degil', () {
      expect(purchasableProductIds, hasLength(8));
      expect(purchasableProductIds.toSet(), hasLength(8));
    });
  });

  test('loader sonucu productId → fiyat metni', () async {
    final c = ProviderContainer(overrides: [
      storePricesLoaderProvider.overrideWithValue(() async => {'qulopurple50': '₺39,99'}),
    ]);
    addTearDown(c.dispose);
    expect(await c.read(storePricesProvider.future), {'qulopurple50': '₺39,99'});
  });

  test('loader patlarsa boş map', () async {
    final c = ProviderContainer(overrides: [
      storePricesLoaderProvider.overrideWithValue(() async => throw Exception('rc')),
    ]);
    addTearDown(c.dispose);
    expect(await c.read(storePricesProvider.future), isEmpty);
  });

  test('boş map cache lenmez: dinleyici kapanınca yeniden çekilir (autoDispose)', () async {
    var callCount = 0;
    Future<Map<String, String>> loader() async {
      callCount++;
      return callCount == 1 ? const {} : {'qulopurple50': '₺39,99'};
    }

    final c = ProviderContainer(overrides: [
      storePricesLoaderProvider.overrideWithValue(loader),
    ]);
    addTearDown(c.dispose);

    final sub = c.listen(storePricesProvider.future, (_, __) {});
    expect(await c.read(storePricesProvider.future), isEmpty);
    sub.close();

    await c.pump(); // autoDispose scheduler'ın dinleyicisiz sağlayıcıyı temizlemesini bekle

    expect(await c.read(storePricesProvider.future), {'qulopurple50': '₺39,99'});
    expect(callCount, 2);
  });

  test('dolu map keepAlive ile kalıcı cache lenir: dinleyici kapansa da tekrar çekilmez', () async {
    var callCount = 0;
    Future<Map<String, String>> loader() async {
      callCount++;
      return {'qulopurple50': '₺39,99'};
    }

    final c = ProviderContainer(overrides: [
      storePricesLoaderProvider.overrideWithValue(loader),
    ]);
    addTearDown(c.dispose);

    final sub = c.listen(storePricesProvider.future, (_, __) {});
    expect(await c.read(storePricesProvider.future), isNotEmpty);
    sub.close();

    await c.pump();

    expect(await c.read(storePricesProvider.future), {'qulopurple50': '₺39,99'});
    expect(callCount, 1);
  });
}
