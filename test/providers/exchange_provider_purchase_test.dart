import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

import '../helpers/fake_repositories.dart';

/// Takas ve guc satin alma — para harcayan iki yol.
///
/// Kural: bakiye ve envanter YALNIZCA sunucu islemi onayladiktan sonra
/// sunucudan tazelenir. Hata durumunda (ozellikle `INSUFFICIENT_DIAMONDS`)
/// hicbir sey tazelenmez ve hata kodu cagirana doner — ekran paywall'a bu
/// kodla gider. Repository'ye tam bir kez gidilir (gizli tekrar = cift tahsilat).
const _insufficient = ServerFailure(code: 'INSUFFICIENT_DIAMONDS', statusCode: 400);

({ProviderContainer container, FakeExchangeRepository exchange, FakeDiamondRepository diamond})
    _setup({
  List<PowerInventoryItem> inventory = const [],
  AppFailure? convertFailure,
  AppFailure? buyPowerFailure,
}) {
  final exchange = FakeExchangeRepository(
    inventory: inventory,
    convertFailure: convertFailure,
    buyPowerFailure: buyPowerFailure,
  );
  final diamond = FakeDiamondRepository(balance: const DiamondBalance(green: 4, purple: 75));
  final container = ProviderContainer(overrides: [
    exchangeRepositoryProvider.overrideWithValue(exchange),
    diamondRepositoryProvider.overrideWithValue(diamond),
  ]);
  addTearDown(container.dispose);
  return (container: container, exchange: exchange, diamond: diamond);
}

void main() {
  group('convert — yesil → mor', () {
    test('basarida true doner ve bakiye sunucudan tazelenir', () async {
      final s = _setup();

      final ok = await s.container.read(exchangeProvider.notifier).convert(30);

      expect(ok, isTrue);
      expect(s.exchange.convertCallCount, 1);
      expect(s.diamond.getBalanceCallCount, 1);
      expect(s.container.read(diamondProvider).value, const DiamondBalance(green: 4, purple: 75));
    });

    test('yetersiz bakiyede false — bakiye tazelenmez, tek cagri', () async {
      final s = _setup(convertFailure: _insufficient);

      final ok = await s.container.read(exchangeProvider.notifier).convert(30);

      expect(ok, isFalse);
      expect(s.exchange.convertCallCount, 1);
      expect(s.diamond.getBalanceCallCount, 0);
    });
  });

  group('buyPower', () {
    test('basarida envanter ve bakiye sunucudan tazelenir', () async {
      final s = _setup(inventory: const [PowerInventoryItem(powerName: 'HINT', count: 2)]);

      final result =
          await s.container.read(exchangeProvider.notifier).buyPower('HINT', 'PURPLE', 2);

      expect(result.when(success: (r) => r.newCount, failure: (_) => null), 2);
      expect(s.exchange.getInventoryCallCount, 1);
      expect(s.diamond.getBalanceCallCount, 1);
      expect(s.container.read(exchangeProvider).getCount('HINT'), 2);
    });

    test('yetersiz bakiyede hata kodu cagirana doner, hicbir sey tazelenmez', () async {
      final s = _setup(buyPowerFailure: _insufficient);

      final result =
          await s.container.read(exchangeProvider.notifier).buyPower('HINT', 'PURPLE', 1);

      final failure = result.when<AppFailure?>(success: (_) => null, failure: (f) => f);
      expect((failure as ServerFailure).code, 'INSUFFICIENT_DIAMONDS');
      expect(s.exchange.buyPowerCallCount, 1);
      expect(s.exchange.getInventoryCallCount, 0);
      expect(s.diamond.getBalanceCallCount, 0);
    });
  });

  group('fetchAll', () {
    test('envanter hatasi onceki envanteri silmez, fiyatlar yine yazilir', () async {
      final s = _setup(inventory: const [PowerInventoryItem(powerName: 'HALF', count: 1)]);
      final notifier = s.container.read(exchangeProvider.notifier);
      await notifier.fetchAll();

      s.exchange
        ..inventoryFailure = const NetworkFailure()
        ..rates = const RatesResponse(convertRatio: 4, powers: []);
      await notifier.fetchAll();

      final state = s.container.read(exchangeProvider);
      expect(state.getCount('HALF'), 1);
      expect(state.rates?.convertRatio, 4);
      expect(state.isLoading, isFalse);
    });

    test('fiyat hatasi onceki fiyatlari silmez', () async {
      final s = _setup();
      final notifier = s.container.read(exchangeProvider.notifier);
      await notifier.fetchAll();

      s.exchange.ratesFailure = const NetworkFailure();
      await notifier.fetchAll();

      expect(s.container.read(exchangeProvider).rates?.convertRatio, 3);
      expect(s.container.read(exchangeProvider).isLoading, isFalse);
    });

    test('getCount ayni gucun satirlarini toplar, olmayan guc 0', () async {
      final s = _setup(inventory: const [
        PowerInventoryItem(powerName: 'HINT', count: 2),
        PowerInventoryItem(powerName: 'HINT', count: 1),
        PowerInventoryItem(powerName: 'HALF', count: 5),
      ]);
      await s.container.read(exchangeProvider.notifier).fetchAll();

      final state = s.container.read(exchangeProvider);
      expect(state.getCount('HINT'), 3);
      expect(state.getCount('ORACLE'), 0);
    });
  });
}
