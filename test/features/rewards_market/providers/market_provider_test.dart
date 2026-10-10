import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/fixed_user_notifier.dart';

const _view = MarketView(balance: 10, items: [], monthlyCap: 150, usedThisMonth: 0);

(ProviderContainer, FakeRewardsRepository, void Function(Duration)) _setup({MarketView view = _view}) {
  final repo = FakeRewardsRepository(market: view);
  var now = DateTime(2026, 9, 29, 12);
  final container = ProviderContainer(overrides: [
    rewardsRepositoryProvider.overrideWithValue(repo),
    marketClockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(container.dispose);
  return (container, repo, (d) => now = now.add(d));
}

void main() {
  test('60 sn tazelik: ikinci load istek atmaz; süre dolunca ya da force ile atar', () async {
    final (container, repo, advance) = _setup();
    final notifier = container.read(marketProvider.notifier);
    await notifier.load();
    await notifier.load();
    expect(repo.marketCountries, hasLength(1));
    advance(const Duration(seconds: 61));
    await notifier.load();
    expect(repo.marketCountries, hasLength(2));
    await notifier.load(force: true);
    expect(repo.marketCountries, hasLength(3));
    expect(container.read(marketProvider).valueOrNull, _view);
  });

  test('eşzamanlı iki load tek istek', () async {
    final (container, repo, _) = _setup();
    final notifier = container.read(marketProvider.notifier);
    await Future.wait([notifier.load(), notifier.load(force: true)]);
    expect(repo.marketCountries, hasLength(1));
  });

  test('önizleme ülkesi: seçim zorla yeniden yükler ve parametre olarak gider; aynı seçim istek atmaz', () async {
    final (container, repo, _) = _setup();
    final notifier = container.read(marketProvider.notifier);
    await notifier.load();
    await notifier.selectCountry('TH');
    await notifier.selectCountry('TH');
    await notifier.selectCountry(null);
    expect(repo.marketCountries, [null, 'TH', null]);
    expect(notifier.previewCountry, isNull);
  });

  test('yenileme hatası eldeki veriyi silmez (hata + önceki değer)', () async {
    final (container, repo, _) = _setup();
    final notifier = container.read(marketProvider.notifier);
    await notifier.load();
    repo.marketFailure = const NetworkFailure();
    await notifier.load(force: true);
    final state = container.read(marketProvider);
    expect(state.hasError, isTrue);
    expect(state.valueOrNull, _view);
  });

  test('ilk yükleme hatası: veri yok, hata var', () async {
    final (container, repo, _) = _setup();
    repo.marketFailure = const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403);
    await container.read(marketProvider.notifier).load();
    final state = container.read(marketProvider);
    expect(state.valueOrNull, isNull);
    expect(state.error, isA<ServerFailure>());
  });

  test('RAINBOW_NOT_AVAILABLE önceki veriyi TAŞIMAZ (erişim kapandı) ve tazeliği sıfırlar', () async {
    final (container, repo, _) = _setup();
    final notifier = container.read(marketProvider.notifier);
    await notifier.load();
    repo.marketFailure = const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403);
    await notifier.load(force: true);
    final state = container.read(marketProvider);
    expect(state.hasError, isTrue);
    expect(state.valueOrNull, isNull, reason: 'kapalı hesapta eski bakiye/katalog gösterilmez');

    repo.marketFailure = null;
    await notifier.load();
    expect(repo.marketCountries, hasLength(3), reason: 'erişim geri gelince zorlamasız load istek atar');
    expect(container.read(marketProvider).valueOrNull, _view);
  });

  test('invalidate (çıkış): değer, önizleme ülkesi ve tazelik sıfırlanır', () async {
    final (container, repo, _) = _setup();
    await container.read(marketProvider.notifier).selectCountry('TH');
    expect(container.read(marketProvider).valueOrNull, _view);

    container.invalidate(marketProvider);

    expect(container.read(marketProvider).valueOrNull, isNull, reason: 'sonraki hesap önceki bakiyeyi görmez');
    final notifier = container.read(marketProvider.notifier);
    expect(notifier.previewCountry, isNull, reason: 'test admin önizleme ülkesi taşınmaz');
    await notifier.load();
    expect(repo.marketCountries, ['TH', null], reason: 'taze istek, ülke parametresiz');
  });

  test('çıkış sırasında uçuştaki eski yanıt sonraki oturuma yazılmaz', () async {
    final (container, repo, _) = _setup();
    repo.marketGate = Completer<void>();
    final inFlight = container.read(marketProvider.notifier).load();

    container.invalidate(marketProvider);
    container.read(marketProvider);
    repo.marketGate!.complete();
    await inFlight;

    expect(container.read(marketProvider).valueOrNull, isNull);
  });

  test('applyRedeem: bakiye ve bu ay kullanım istek atmadan güncellenir', () async {
    final (container, repo, _) =
        _setup(view: const MarketView(balance: 1000, items: [], monthlyCap: 150, usedThisMonth: 20));
    final notifier = container.read(marketProvider.notifier);
    await notifier.load();

    notifier.applyRedeem(balance: 949, price: 51);

    final view = container.read(marketProvider).requireValue!;
    expect(view.balance, 949);
    expect(view.usedThisMonth, 71);
    expect(view.monthlyCap, 150);
    expect(repo.marketCountries, hasLength(1), reason: 'yerel uygulama, istek yok');
  });

  test('applyRedeem: market henüz yüklenmemişse değer oluşturmaz', () async {
    final (container, _, _) = _setup();
    container.read(marketProvider.notifier).applyRedeem(balance: 949, price: 51);
    expect(container.read(marketProvider).valueOrNull, isNull);
  });

  test('başarılı yükleme Rainbow bakiyesini kullanıcıya da yazar (tek bakiye kaynağı)', () async {
    final repo = FakeRewardsRepository(
      market: const MarketView(balance: 777, items: [], monthlyCap: 150, usedThisMonth: 0),
    );
    final container = ProviderContainer(overrides: [
      rewardsRepositoryProvider.overrideWithValue(repo),
      userProvider.overrideWith(() => FixedUserNotifier(const UserModel(
            id: 'u1', email: 'u1@qulo.test', rainbowEnabled: true, rainbowDiamonds: 5, purpleDiamonds: 40,
          ))),
    ]);
    addTearDown(container.dispose);
    await container.read(userProvider.future);

    await container.read(marketProvider.notifier).load();

    final user = container.read(userProvider).requireValue!;
    expect(user.rainbowDiamonds, 777);
    expect(user.purpleDiamonds, 40);
  });
}
