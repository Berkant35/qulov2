import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/data/repositories/referral_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/referral_provider.dart';

/// Davet (referral) — odul yolu. Sayfa dort ayri istekle dolar; biri
/// basarisiz olsa da digerleri gosterilmeli. Kod normalizasyonu SUNUCUDA
/// (`referral_repository_test`): istemci kodu oldugu gibi gonderir.
void main() {
  group('fetchAll', () {
    test('kod, istatistik ve gecmis yuklenir; davet edilmediysem kod girilebilir', () async {
      final h = _Harness();

      await h.notifier.fetchAll();

      expect(h.state.code, 'AB12CD');
      expect(h.state.stats?.completed, 2);
      expect(h.state.history.single.refereeName, 'Ayse');
      expect(h.state.hasAppliedCode, isFalse);
    });

    test('beni davet eden varsa adi ve durumu gosterilir', () async {
      final h = _Harness()
        ..repo.referrer = const Success(MyReferrerResponse(referrerName: 'Mehmet', status: 'completed'));

      await h.notifier.fetchAll();

      expect(h.state.hasAppliedCode, isTrue);
      expect(h.state.referredBy, 'Mehmet');
      expect(h.state.referralStatus, 'completed');
    });

    test('bir istek basarisiz olsa da digerleri gosterilir', () async {
      final h = _Harness()..repo.stats = const Failure(NetworkFailure());

      await h.notifier.fetchAll();

      expect(h.state.stats, isNull);
      expect(h.state.code, 'AB12CD');
      expect(h.state.history, hasLength(1));
    });

    test('hepsi basarisiz olsa da sayfa hata ekranina dusmez — bos durum', () async {
      final h = _Harness()
        ..repo.code = const Failure(NetworkFailure())
        ..repo.stats = const Failure(NetworkFailure())
        ..repo.history = const Failure(NetworkFailure())
        ..repo.referrer = const Failure(NetworkFailure());

      await h.notifier.fetchAll();

      expect(h.container.read(referralProvider).hasError, isFalse);
      expect(h.state.code, isNull);
      expect(h.state.history, isEmpty);
    });
  });

  group('kod uygulama', () {
    test('basarida davet eden ve "beklemede" yazilir, mevcut veriler korunur', () async {
      final h = _Harness();
      await h.notifier.fetchAll();

      final result = await h.notifier.applyCode('ab12cd');

      expect(result.isSuccess, isTrue);
      expect(h.repo.applied, ['ab12cd']);
      expect(h.state.hasAppliedCode, isTrue);
      expect(h.state.referredBy, 'Mehmet');
      expect(h.state.referralStatus, 'pending');
      expect(h.state.code, 'AB12CD', reason: 'kendi kodum silinmemeli');
      expect(h.state.stats?.completed, 2);
    });

    test('hata (kendi kodu) durumu degistirmez', () async {
      final h = _Harness()
        ..repo.applyResult = const Failure(ServerFailure(code: 'SELF_REFERRAL', statusCode: 400));
      await h.notifier.fetchAll();

      final result = await h.notifier.applyCode('AB12CD');

      expect(result.isFailure, isTrue);
      expect(h.state.hasAppliedCode, isFalse);
      expect(h.state.referralStatus, isNull);
    });

    test('dogrulama sonucu oldugu gibi iletilir', () async {
      final h = _Harness();

      final result = await h.notifier.validateCode('XY99');

      expect(h.repo.validated, ['XY99']);
      expect(result.when(success: (r) => r.referrerName, failure: (_) => null), 'Mehmet');
    });
  });
}

class _Harness {
  _Harness() {
    container = ProviderContainer(overrides: [referralRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
  }

  final repo = _FakeReferralRepository();
  late final ProviderContainer container;

  ReferralNotifier get notifier => container.read(referralProvider.notifier);
  ReferralState get state => container.read(referralProvider).requireValue;
}

class _FakeReferralRepository implements ReferralRepository {
  Result<String> code = const Success('AB12CD');
  Result<ReferralStats> stats =
      const Success(ReferralStats(total: 3, pending: 1, completed: 2, remaining: 8));
  Result<List<ReferralItem>> history = const Success([
    ReferralItem(
      id: 'r1',
      refereeName: 'Ayse',
      status: 'completed',
      createdAt: '2026-09-01T10:00:00Z',
      completedAt: '2026-09-02T10:00:00Z',
    ),
  ]);
  Result<MyReferrerResponse> referrer = const Success(MyReferrerResponse());
  Result<String> applyResult = const Success('Mehmet');

  final applied = <String>[];
  final validated = <String>[];

  @override
  Future<Result<String>> getMyCode() async => code;

  @override
  Future<Result<ReferralStats>> getStats() async => stats;

  @override
  Future<Result<List<ReferralItem>>> getHistory() async => history;

  @override
  Future<Result<MyReferrerResponse>> getMyReferrer() async => referrer;

  @override
  Future<Result<String>> applyCode(String code) async {
    applied.add(code);
    return applyResult;
  }

  @override
  Future<Result<ValidateCodeResponse>> validateCode(String code) async {
    validated.add(code);
    return const Success(ValidateCodeResponse(valid: true, referrerName: 'Mehmet'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeReferralRepository.${invocation.memberName}');
}
