import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

import '../helpers/fake_repositories.dart';

/// Elmas provider'i — para yolu.
///
/// RevenueCat'e giren iki metot (`purchaseConsumable`, `purchaseByProductId`)
/// burada test EDILMIYOR: ikisi de statik `RevenueCatService`'e bagli ve
/// `isConfigured` false oldugu icin testte erken donuyorlar. Test edilen
/// kisim, sunucu tarafina bakan akis: bakiye tazeleme ve `purchase` delegasyonu.
ProviderContainer _container(FakeDiamondRepository fake) {
  final container = ProviderContainer(
    overrides: [diamondRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('baslangic durumu sifir bakiye — ag cagrisi yapilmaz', () async {
    final fake = FakeDiamondRepository();
    final c = _container(fake);

    final initial = await c.read(diamondProvider.future);

    expect(initial, const DiamondBalance(green: 0, purple: 0));
    expect(fake.getBalanceCallCount, 0);
  });

  test('fetchBalance basarili olunca state AsyncData olur', () async {
    final fake = FakeDiamondRepository(
      balance: const DiamondBalance(green: 7, purple: 430),
    );
    final c = _container(fake);
    await c.read(diamondProvider.future);

    await c.read(diamondProvider.notifier).fetchBalance();

    expect(c.read(diamondProvider).valueOrNull?.purple, 430);
    expect(fake.getBalanceCallCount, 1);
  });

  test('fetchBalance hatasi AsyncError olur — eski bakiye dogru sanilmasin', () async {
    // Bakiye ekraninin sessizce eski/sifir deger gostermemesi icin hata
    // state'e tasinmali; UI `.when(error:)` ile gercek durumu gosterebilsin.
    final fake = FakeDiamondRepository(balanceFailure: const NetworkFailure());
    final c = _container(fake);
    await c.read(diamondProvider.future);

    await c.read(diamondProvider.notifier).fetchBalance();

    expect(c.read(diamondProvider).hasError, isTrue);
    expect(c.read(diamondProvider).error, isA<NetworkFailure>());
  });

  test('purchase repository\'ye dogru urun kimligiyle delege eder', () async {
    final fake = FakeDiamondRepository();
    final c = _container(fake);
    await c.read(diamondProvider.future);

    await c.read(diamondProvider.notifier).purchase('qulopurple400');

    expect(fake.purchaseCallCount, 1);
    expect(fake.lastPurchasedProductId, 'qulopurple400');
  });

  test('basarili satin almadan SONRA bakiye tazelenir', () async {
    // Sunucu krediyi yazdi; istemcinin yeni bakiyeyi okumasi gerekiyor.
    final fake = FakeDiamondRepository(balance: const DiamondBalance(green: 0, purple: 400));
    final c = _container(fake);
    await c.read(diamondProvider.future);

    await c.read(diamondProvider.notifier).purchase('qulopurple400');

    expect(fake.getBalanceCallCount, 1);
    expect(c.read(diamondProvider).valueOrNull?.purple, 400);
  });

  test('satin alma BASARISIZSA bakiye tazelenmez ve hata cagirana doner', () async {
    // Bosuna istek atmamak disinda bir sebep daha var: basarisiz satin almadan
    // sonra bakiye tazelemek, kullaniciya "islem oldu" izlenimi verebilir.
    final fake = FakeDiamondRepository(
      purchaseFailure: const ServerFailure(code: 'PURCHASE_VERIFICATION_FAILED'),
    );
    final c = _container(fake);
    await c.read(diamondProvider.future);

    final result = await c.read(diamondProvider.notifier).purchase('qulopurple400');

    expect(result.isFailure, isTrue);
    expect(fake.getBalanceCallCount, 0);
  });

  test('fetchHistory repository sonucunu oldugu gibi gecirir', () async {
    final fake = FakeDiamondRepository();
    final c = _container(fake);
    await c.read(diamondProvider.future);

    final result = await c.read(diamondProvider.notifier).fetchHistory(page: 2);

    expect(result.isSuccess, isTrue);
    expect(result.when(success: (d) => d.page, failure: (_) => -1), 2);
  });
}
