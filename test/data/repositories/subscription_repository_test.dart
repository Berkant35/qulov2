import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/subscription_service.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/repositories/subscription_repository.dart';

/// Abonelik repository'si — elmastan sonraki ikinci para yolu.
///
/// Sunucu sözleşmesi (`subscription.routes.ts:12`): `product_id` zorunlu,
/// `transaction_id` opsiyonel, **platform alanı yok**. Elmas tarafında hardcoded
/// `'ios'` bir buga dönüşmüştü; burada öyle bir alan hiç olmamalı, testler bunu
/// da doğruluyor.
class _FakeSubscriptionService implements SubscriptionService {
  _FakeSubscriptionService({this.response, this.stats, this.error});

  final SubscriptionStatusResponse? response;
  final DailyStats? stats;
  final DioException? error;

  Map<String, dynamic>? lastActivatePayload;
  int activateCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<SubscriptionStatusResponse> getStatus() async {
    if (error != null) throw _err;
    return response!;
  }

  @override
  Future<SubscriptionStatusResponse> activate(Map<String, dynamic> data) async {
    activateCallCount++;
    lastActivatePayload = data;
    if (error != null) throw _err;
    return response!;
  }

  @override
  Future<DailyStats> getDailyStats() async {
    if (error != null) throw _err;
    return stats!;
  }
}

const _limits = SubscriptionLimits(
  dailyDiscovers: -1,
  maxQuestions: 10,
  dailyUndos: -1,
  monthlyPurpleBonus: 1500,
  passportMode: true,
  hasAds: false,
);

SubscriptionStatusResponse _premium() => const SubscriptionStatusResponse(
      subscription: SubscriptionInfo(
        plan: 'premium',
        status: 'active',
        expiresAt: '2026-10-08T00:00:00.000Z',
        isActive: true,
      ),
      limits: _limits,
    );

DioException _dio(DioExceptionType type, {int? status, dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: status,
              data: body,
            ),
    );

void main() {
  group('getStatus', () {
    test('sarmalayicidan yalnizca subscription cikarilir', () async {
      // Sunucu {subscription, limits} donuyor; repository sadece ilkini veriyor.
      final repo = SubscriptionRepository(_FakeSubscriptionService(response: _premium()));

      final result = await repo.getStatus();

      expect(result.isSuccess, isTrue);
      final info = result.when(success: (d) => d, failure: (_) => null)!;
      expect(info.plan, 'premium');
      expect(info.isActive, isTrue);
      expect(info.isPremium, isTrue);
      expect(info.isPlus, isFalse);
    });

    test('ag hatasi Failure(NetworkFailure) olur', () async {
      final repo = SubscriptionRepository(
        _FakeSubscriptionService(error: _dio(DioExceptionType.connectionError)),
      );

      final result = await repo.getStatus();

      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });
  });

  group('activate — para yolu', () {
    test('product_id gonderilir', () async {
      final fake = _FakeSubscriptionService(response: _premium());

      await SubscriptionRepository(fake).activate('qulopremiummonthly2');

      expect(fake.lastActivatePayload!['product_id'], 'qulopremiummonthly2');
    });

    test('transaction_id verilince payload\'a eklenir', () async {
      final fake = _FakeSubscriptionService(response: _premium());

      await SubscriptionRepository(fake)
          .activate('quloplusmonthly2', transactionId: 'tx-sub-1');

      expect(fake.lastActivatePayload!['transaction_id'], 'tx-sub-1');
    });

    test('transaction_id yoksa anahtar HIC gonderilmez, null olarak degil', () async {
      // Elmas tarafiyla ayni gerekce: sunucuda null bir makbuz kimligi
      // "gecersiz makbuz" ile karistirilabilir.
      final fake = _FakeSubscriptionService(response: _premium());

      await SubscriptionRepository(fake).activate('quloplusmonthly2');

      expect(fake.lastActivatePayload!.containsKey('transaction_id'), isFalse);
    });

    test('payload SADECE sozlesmedeki alanlari tasir — platform gibi fazlalik yok', () async {
      // subscription.routes.ts:12 semasi product_id + transaction_id. Elmas
      // tarafinda hardcoded 'platform' bir buga donusmustu; burada eklenmesin.
      final fake = _FakeSubscriptionService(response: _premium());

      await SubscriptionRepository(fake).activate('quloplusmonthly2', transactionId: 'tx-1');

      expect(fake.lastActivatePayload!.keys.toSet(), {'product_id', 'transaction_id'});
    });

    test('sunucu hata kodu ServerFailure olarak tasinir ve servis bir kez cagrilir', () async {
      // Para yolunda sessiz tekrar = cift abonelik riski.
      final fake = _FakeSubscriptionService(
        error: _dio(DioExceptionType.badResponse,
            status: 402, body: {'error': {'code': 'SUBSCRIPTION_VERIFICATION_FAILED'}}),
      );

      final result = await SubscriptionRepository(fake).activate('quloplusmonthly2');

      final failure = result.when(success: (_) => null, failure: (f) => f);
      expect((failure as ServerFailure).code, 'SUBSCRIPTION_VERIFICATION_FAILED');
      expect(failure.statusCode, 402);
      expect(fake.activateCallCount, 1);
    });
  });

  group('getDailyStats', () {
    test('sinirsiz degerler (-1) modele oldugu gibi gecer', () async {
      // -1 "sinirsiz" demek; 0 ile karistirilirsa premium kullaniciya
      // "hakkin bitti" denir.
      const stats = DailyStats(
        dailyDiscoversUsed: 12,
        dailyDiscoversLimit: -1,
        dailyUndosUsed: 3,
        dailyUndosLimit: -1,
        questionsCreated: 4,
        questionsLimit: 10,
        monthlyPurpleBonus: 1500,
        passportMode: true,
        hasAds: false,
      );
      final repo = SubscriptionRepository(_FakeSubscriptionService(stats: stats));

      final result = await repo.getDailyStats();

      final data = result.when(success: (d) => d, failure: (_) => null)!;
      expect(data.isDiscoverUnlimited, isTrue);
      expect(data.isUndoUnlimited, isTrue);
      expect(data.questionsLimit, 10);
    });

    test('hata Failure olur — limit ekrani uydurma sayi gostermesin', () async {
      final repo = SubscriptionRepository(
        _FakeSubscriptionService(error: _dio(DioExceptionType.receiveTimeout)),
      );

      final result = await repo.getDailyStats();

      expect(result.when(success: (_) => null, failure: (f) => f), isA<TimeoutFailure>());
    });
  });
}
