import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/subscription_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fake_repositories.dart';

/// Satın alma sonrası cüzdan senkronu (para yolu, 2.0.18 kullanıcı bildirimi:
/// "premium alıyorum, soru çözme ekranımda mor elmaslarım güncellenmiyor").
///
/// Quiz / sohbet sorusu AppBar'ı (`CompactDiamondBalance`) ve koç notu bakiyeyi
/// `userProvider`'dan okur. Aylık mor bonusu sunucuda `POST /subscriptions/activate`
/// içinde EŞZAMANLI yatar; ama satın alma yolu yalnız abonelik durumunu tazeliyordu —
/// `userProvider` uygulama açılışındaki bakiyede kalıyordu (canlı kayıt: 08:15:29
/// +1500 yattı, quiz 08:15:37'de açıldı, AppBar 6 gösterdi).
const _before = UserModel(id: 'u1', email: 'u1@qulo.test', purpleDiamonds: 6, greenDiamonds: 3);
final _afterGrant = _before.withPurpleDiamonds(1506);

/// Sunucu gibi: `activate` başarılıysa bonusu yatırır (sonraki getMe/balance yeni bakiyeyi döner).
class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository(this.users, this.diamonds, {this.activateFailure});

  final FakeUserRepository users;
  final FakeDiamondRepository diamonds;
  final AppFailure? activateFailure;
  int activateCalls = 0;
  bool active = false;

  @override
  Future<Result<SubscriptionInfo>> activate(String productId, {String? transactionId}) async {
    activateCalls++;
    if (activateFailure != null) return Failure(activateFailure!);
    active = true;
    users.user = _afterGrant;
    diamonds.balance = const DiamondBalance(green: 3, purple: 1506);
    return Success(_premium);
  }

  @override
  Future<Result<SubscriptionInfo>> getStatus() async =>
      Success(active ? _premium : SubscriptionInfo.free());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeSubscriptionRepository.${invocation.memberName}');
}

const _premium = SubscriptionInfo(plan: 'premium', status: 'active', isActive: true);

/// `build()` kimlik/ağ okumasın — test yalnız satın alma sonrası adımı sürer.
class _FreeSubscription extends SubscriptionNotifier {
  @override
  Future<SubscriptionInfo> build() async => SubscriptionInfo.free();
}

({ProviderContainer c, FakeUserRepository users, FakeDiamondRepository diamonds,
    _FakeSubscriptionRepository subs}) _setup({AppFailure? activateFailure}) {
  final users = FakeUserRepository(_before);
  final diamonds = FakeDiamondRepository(balance: const DiamondBalance(green: 3, purple: 6));
  final subs = _FakeSubscriptionRepository(users, diamonds, activateFailure: activateFailure);
  final c = ProviderContainer(overrides: [
    userRepositoryProvider.overrideWithValue(users),
    diamondRepositoryProvider.overrideWithValue(diamonds),
    subscriptionRepositoryProvider.overrideWithValue(subs),
    subscriptionProvider.overrideWith(_FreeSubscription.new),
  ]);
  addTearDown(c.dispose);
  return (c: c, users: users, diamonds: diamonds, subs: subs);
}

/// Uygulama açılışı gibi: AppBar bakiyesi ve elmas ekranı bakiyesi yüklü.
Future<void> _loadWallet(ProviderContainer c) async {
  await c.read(subscriptionProvider.future);
  await c.read(userProvider.notifier).fetchMe();
  await c.read(diamondProvider.notifier).fetchBalance();
}

void main() {
  group('abonelik satın alındıktan sonra', () {
    test('AppBar bakiyesi (userProvider) aylık mor bonusunu gösterir', () async {
      final s = _setup();
      await _loadWallet(s.c);
      expect(s.c.read(userProvider).valueOrNull?.purpleDiamonds, 6);

      await s.c
          .read(subscriptionProvider.notifier)
          .confirmPurchase('qulopremiummonthly2', transactionId: '2026-11-11T08:15:25Z');

      expect(s.subs.activateCalls, 1);
      expect(s.c.read(subscriptionProvider).valueOrNull?.isPremium, isTrue);
      expect(s.c.read(userProvider).valueOrNull?.purpleDiamonds, 1506,
          reason: 'quiz / sohbet sorusu AppBar\'ı userProvider\'dan okur');
      expect(s.c.read(diamondProvider).valueOrNull?.purple, 1506,
          reason: 'elmas ekranı ve güç sayfası diamondProvider\'dan okur');
    });

    test('sunucu bildirimi başarısız olsa da cüzdan sunucudan yeniden okunur', () async {
      // Webhook bonusu yatırmış olabilir; istemci bakiyeyi tahmin etmez, sunucuya sorar.
      final s = _setup(activateFailure: const NetworkFailure());
      await _loadWallet(s.c);
      final getMeBefore = s.users.getMeCallCount;
      final balanceBefore = s.diamonds.getBalanceCallCount;

      await s.c.read(subscriptionProvider.notifier).confirmPurchase('qulopremiummonthly2');

      expect(s.users.getMeCallCount, getMeBefore + 1);
      expect(s.diamonds.getBalanceCallCount, balanceBefore + 1);
      expect(s.c.read(userProvider).valueOrNull?.purpleDiamonds, 6);
    });
  });

  test('elmas paketi satın alındıktan sonra AppBar bakiyesi de güncellenir', () async {
    final s = _setup();
    await _loadWallet(s.c);
    // Sunucu `POST /diamonds/purchase` içinde krediyi yazar.
    s.users.user = _before.withPurpleDiamonds(406);
    s.diamonds.balance = const DiamondBalance(green: 3, purple: 406);

    await s.c
        .read(diamondProvider.notifier)
        .confirmPurchase('qulopurple400', transactionId: 'tx-1');

    expect(s.diamonds.purchaseCallCount, 1);
    expect(s.diamonds.lastTransactionId, 'tx-1');
    expect(s.c.read(diamondProvider).valueOrNull?.purple, 406);
    expect(s.c.read(userProvider).valueOrNull?.purpleDiamonds, 406);
  });
}
