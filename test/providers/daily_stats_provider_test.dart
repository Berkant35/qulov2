import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/repositories/subscription_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

/// Gunluk limitler — soru slotu (`questions_fab`, `questions_screen_mixin`),
/// geri alma (`discover_card_view`) ve aylik fayda karti buradan okur.
///
/// Istek basarisizsa deger onbellekte kalir (invalidate edilene kadar). Eskiden
/// yedek her zaman ucretsiz limitlerdi: tek bir gecici hata Premium kullaniciya
/// 4 soru slotu ve kilitli geri alma gosterirdi. Limitler economy config
/// yedeginden (`EconomyConfig.fallback`): ucretsiz 50/0/4, Plus ∞/3/6, Premium ∞/∞/10.
class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository(this.result);

  final Result<DailyStats> result;

  @override
  Future<Result<DailyStats>> getDailyStats() async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeSubscriptionRepository.${invocation.memberName}');
}

class _SeededSubscription extends SubscriptionNotifier {
  _SeededSubscription(this.info);

  final Future<SubscriptionInfo> info;

  @override
  Future<SubscriptionInfo> build() => info;
}

Future<DailyStats> _stats(
  Result<DailyStats> serverResult, {
  Future<SubscriptionInfo>? subscription,
}) async {
  final container = ProviderContainer(overrides: [
    subscriptionRepositoryProvider.overrideWithValue(_FakeSubscriptionRepository(serverResult)),
    subscriptionProvider.overrideWith(
      () => _SeededSubscription(subscription ?? Future.value(SubscriptionInfo.free())),
    ),
  ]);
  addTearDown(container.dispose);
  if (subscription != null) {
    // Abonelik yuklendiyse once onu bekle (gercekte uygulama acilisinda yuklenir).
    await container.read(subscriptionProvider.future).timeout(
          const Duration(milliseconds: 50),
          onTimeout: () => SubscriptionInfo.free(),
        );
  }
  return container.read(dailyStatsProvider.future);
}

const _networkDown = Failure<DailyStats>(NetworkFailure());

SubscriptionInfo _active(String plan) =>
    SubscriptionInfo(plan: plan, status: 'active', isActive: true);

void main() {
  test('basarida sunucu degeri oldugu gibi gecer', () async {
    const server = DailyStats(
      dailyDiscoversUsed: 12,
      dailyDiscoversLimit: -1,
      dailyUndosUsed: 1,
      dailyUndosLimit: 3,
      questionsCreated: 5,
      questionsLimit: 6,
      monthlyPurpleBonus: 500,
      passportMode: false,
      hasAds: false,
    );

    expect(await _stats(const Success(server)), server);
  });

  group('istek basarisiz — bilinen aboneligin limitleri', () {
    test('ucretsiz kullanici ucretsiz limitleri gorur', () async {
      final s = await _stats(_networkDown, subscription: Future.value(SubscriptionInfo.free()));

      expect((s.dailyDiscoversLimit, s.dailyUndosLimit, s.questionsLimit), (50, 0, 4));
      expect(s.hasAds, isTrue);
    });

    test('Premium kullanici 4 slota ve kilitli geri almaya DUSMEZ', () async {
      final s = await _stats(_networkDown, subscription: Future.value(_active('premium')));

      expect(s.questionsLimit, 10);
      expect(s.isUndoUnlimited, isTrue);
      expect(s.isDiscoverUnlimited, isTrue);
      expect(s.hasAds, isFalse);
    });

    test('Plus kullanici kendi limitlerini gorur', () async {
      final s = await _stats(_networkDown, subscription: Future.value(_active('plus')));

      expect(s.questionsLimit, 6);
      expect(s.dailyUndosLimit, 3);
      expect(s.isDiscoverUnlimited, isTrue);
    });

    test('sinirsiz -1 olarak tasinir — ekranda "0/999999" gorunmez', () async {
      final s = await _stats(_networkDown, subscription: Future.value(_active('premium')));

      expect(s.dailyUndosLimit, -1);
      expect(s.dailyDiscoversLimit, -1);
    });

    test('suresi dolmus Premium ucretsiz limitlere duser', () async {
      final s = await _stats(
        _networkDown,
        subscription: Future.value(const SubscriptionInfo(plan: 'premium', isActive: false)),
      );

      expect(s.questionsLimit, 4);
      expect(s.isUndoUnlimited, isFalse);
    });

    test('abonelik henuz bilinmiyorsa ucretsize duser', () async {
      final s = await _stats(_networkDown, subscription: Completer<SubscriptionInfo>().future);

      expect(s.questionsLimit, 4);
    });
  });
}
