import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_error.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_outcome.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_session.dart';
import 'package:qulo_v2/features/rewards_market/providers/market_provider.dart';
import 'package:qulo_v2/features/rewards_market/providers/redeem_flow.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../../helpers/fake_repositories.dart';

const _item = MarketItem(id: 'i1', brandKey: 'GRAB', countryCode: 'TH', currency: 'THB', faceValue: 50, rainbowPrice: 51);

const _success = RedeemResult(
  redemption: Redemption(id: 'r1', status: RedemptionStatus.pending, brandKey: 'GRAB', countryCode: 'TH',
      currency: 'THB', faceValue: 50, rainbowPrice: 51),
  balance: 898,
);

const _user = UserModel(id: 'u1', email: 'u1@qulo.test', rainbowEnabled: true, rainbowDiamonds: 1000);

typedef _Harness = ({ProviderContainer container, FakeRewardsRepository rewards, FakeUserRepository users});

/// İtfa iş akışı widget'sız: `testWidgets` binding'i zone'a sızan async hatayı yutar (yeşil ama
/// yanıltıcı); burada düz `test` + `runZonedGuarded` ile "sızıntı yok" doğrudan sınanır. Arka plan
/// yenilemeleri (`load(force: true)`, `fetchMe`) beklenmeden başlatıldığı için sızıntı riski onlarda.
Future<_Harness> _harness(FakeRewardsRepository rewards) async {
  rewards.market ??= const MarketView(balance: 1000, items: [_item], monthlyCap: 150, usedThisMonth: 20);
  final users = FakeUserRepository(_user);
  final container = ProviderContainer(overrides: [
    rewardsRepositoryProvider.overrideWithValue(rewards),
    userRepositoryProvider.overrideWithValue(users),
  ]);
  addTearDown(container.dispose);
  // Gerçek uygulamada kullanıcı açılışta yüklü; market sayfası açılmadan önce yüklenmiş.
  await container.read(userProvider.future);
  await container.read(userProvider.notifier).fetchMe();
  await container.read(marketProvider.notifier).load();
  return (container: container, rewards: rewards, users: users);
}

RedeemFlow _flow(ProviderContainer c) => RedeemFlow(
      redeem: c.read(rewardsRepositoryProvider).redeem,
      user: c.read(userProvider.notifier),
      market: c.read(marketProvider.notifier),
    );

/// Akışı ayrı bir zone'da koşar; akış bittikten ve arka plan işleri boşaldıktan sonra zone'a
/// düşen (yakalanmamış) hataları döndürür.
Future<({RedeemOutcome? outcome, List<Object> leaked})> _guarded(Future<RedeemOutcome> Function() body) async {
  final leaked = <Object>[];
  final done = Completer<RedeemOutcome?>();
  runZonedGuarded(() async {
    final outcome = await body();
    // Beklenmeyen arka plan yenilemeleri (sahte depo anında döner) birkaç mikro görev turunda biter.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    done.complete(outcome);
  }, (error, _) {
    leaked.add(error);
    if (!done.isCompleted) done.complete(null);
  });
  return (outcome: await done.future, leaked: leaked);
}

void main() {
  late List<String> events;

  setUp(() {
    events = [];
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  RedeemSession session() => RedeemSession(itemId: _item.id, sourceItemId: 'b1', newKey: () => 'key-1');

  test('başarı: bakiye + bu ay kullanım yerelde, market arka planda yenilenir; kapat + Görüntüle; sızıntı yok',
      () async {
    final h = await _harness(FakeRewardsRepository(redeemResult: _success));
    h.rewards.market = const MarketView(balance: 898, items: [_item], monthlyCap: 150, usedThisMonth: 71);

    final r = await _guarded(() => _flow(h.container).submit(session(), _item));

    expect(r.leaked, isEmpty);
    expect(r.outcome, isA<RedeemClose>().having((o) => o.error, 'error', isNull).having((o) => o.withView, 'withView', isTrue));
    expect(h.container.read(userProvider).valueOrNull?.rainbowDiamonds, 898);
    expect(h.container.read(marketProvider).valueOrNull?.balance, 898);
    expect(h.container.read(marketProvider).valueOrNull?.usedThisMonth, 71);
    expect(h.rewards.marketCountries, hasLength(2), reason: 'ilk yükleme + zorla yenileme');
    expect(h.rewards.redeemCalls.single.sourceItemId, 'b1');
    expect(events, [AnalyticsEvents.marketRedeemStart, AnalyticsEvents.marketRedeemSuccess]);
  });

  test('başarıdan sonraki arka plan yenilemesi başarısızsa: yerel sonuç korunur, hata zone\'a sızmaz', () async {
    final h = await _harness(FakeRewardsRepository(redeemResult: _success));
    h.rewards.marketFailure = const NetworkFailure();

    final r = await _guarded(() => _flow(h.container).submit(session(), _item));

    expect(r.leaked, isEmpty);
    expect(r.outcome, isA<RedeemClose>());
    final market = h.container.read(marketProvider);
    expect(market.hasError, isTrue, reason: 'hata state\'e yazılır, fırlatılmaz');
    expect(market.valueOrNull?.balance, 898, reason: 'önceki (yerelde güncellenmiş) değer korunur');
  });

  test('sunucu yetersiz: satır içi hata, market yenilenir (yerel bakiye bayattı); bakiye DÜŞMEZ', () async {
    final h = await _harness(FakeRewardsRepository(redeemFailure: const ServerFailure(code: 'INSUFFICIENT_DIAMONDS')));

    final r = await _guarded(() => _flow(h.container).submit(session(), _item));

    expect(r.leaked, isEmpty);
    expect(r.outcome, isA<RedeemInline>().having((o) => o.error.kind, 'kind', RedeemErrorKind.insufficient));
    expect(h.rewards.marketCountries, hasLength(2));
    expect(h.container.read(userProvider).valueOrNull?.rainbowDiamonds, 1000);
    expect(events, [AnalyticsEvents.marketRedeemStart, AnalyticsEvents.marketRedeemError]);
  });

  test('aylık tavan: satır içi hata, parametreler taşınır, market yenilenmez', () async {
    final h = await _harness(FakeRewardsRepository(
      redeemFailure: const ServerFailure(code: 'REWARD_MONTHLY_CAP', params: {'cap': 150, 'used': 140}),
    ));

    final r = await _guarded(() => _flow(h.container).submit(session(), _item));

    expect(r.leaked, isEmpty);
    final inline = r.outcome! as RedeemInline;
    expect(inline.error.kind, RedeemErrorKind.monthlyCap);
    expect(inline.error.params, {'cap': 150, 'used': 140});
    expect(h.rewards.marketCountries, hasLength(1));
  });

  test('RAINBOW_NOT_AVAILABLE: kullanıcı + market yenilenir, sayfa kapanır (Görüntüle yok)', () async {
    final h = await _harness(FakeRewardsRepository(
      redeemFailure: const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403),
    ));
    h.rewards.marketFailure = const ServerFailure(code: 'RAINBOW_NOT_AVAILABLE', statusCode: 403);
    final meCallsBefore = h.users.getMeCallCount;

    final r = await _guarded(() => _flow(h.container).submit(session(), _item));

    expect(r.leaked, isEmpty);
    expect(r.outcome, isA<RedeemClose>().having((o) => o.withView, 'withView', isFalse));
    expect(h.users.getMeCallCount, meCallsBefore + 1);
    expect(h.rewards.marketCountries, hasLength(2));
  });

  test('409 DUPLICATE_REQUEST: işleniyor — kapat + Görüntüle, market yenilenir', () async {
    final h = await _harness(FakeRewardsRepository(
      redeemFailure: const ServerFailure(code: 'DUPLICATE_REQUEST', statusCode: 409),
    ));

    final r = await _guarded(() => _flow(h.container).submit(session(), _item));

    expect(r.leaked, isEmpty);
    expect(r.outcome, isA<RedeemClose>()
        .having((o) => o.error?.kind, 'kind', RedeemErrorKind.processing)
        .having((o) => o.withView, 'withView', isTrue));
    expect(h.rewards.marketCountries, hasLength(2));
  });

  test('istek sürerken ikinci gönderim: RedeemIgnored, tek istek, tek başlangıç olayı; tekrar denemede aynı anahtar',
      () async {
    final h = await _harness(FakeRewardsRepository(redeemFailure: const NetworkFailure())..redeemGate = Completer<void>());
    final s = session();
    final flow = _flow(h.container);

    final first = flow.submit(s, _item);
    expect(s.inFlight, isTrue, reason: 'senkron kısım dönmeden önce çalışır');
    expect(await flow.submit(s, _item), isA<RedeemIgnored>());
    h.rewards.redeemGate!.complete();
    expect(await first, isA<RedeemInline>().having((o) => o.error.kind, 'kind', RedeemErrorKind.network));

    h.rewards.redeemGate = null;
    await flow.submit(s, _item);

    expect(h.rewards.redeemCalls.map((c) => c.idempotencyKey), ['key-1', 'key-1']);
    expect(events.where((e) => e == AnalyticsEvents.marketRedeemStart), hasLength(2),
        reason: 'yoksayılan gönderim olay atmaz; tekrar deneme atar');
  });
}
