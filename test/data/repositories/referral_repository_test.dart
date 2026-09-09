import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/referral_service.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/data/repositories/referral_repository.dart';

/// Davet repository'si — ödül yolu.
///
/// İki sözleşme detayı burada donduruluyor:
/// 1. Yanıt alanı **camelCase `referrerName`** (`referral.routes.ts:73`), oysa
///    istek alanları snake_case. Karıştırılırsa davet uygulama sessizce
///    "eksik alan" hatasına düşer.
/// 2. Kodu **sunucu büyük harfe çeviriyor** (`referral.validator.ts:4`,
///    `.transform(v => v.toUpperCase())`), istemci olduğu gibi gönderiyor —
///    istemcide ikinci bir normalizasyon yapılmamalı.
///
/// Bu repository diğerlerinden farklı olarak `DioException` DIŞI hataları da
/// yakalıyor (`catch (e)`), çünkü yanıt gövdesinden alan okuyor ve tip
/// beklentisi tutmazsa `UnknownFailure` dönüyor.
class _FakeReferralService implements ReferralService {
  _FakeReferralService({this.error, this.codeResponse, this.applyResponse});

  final DioException? error;
  final dynamic codeResponse;
  final dynamic applyResponse;

  Map<String, dynamic>? lastValidatePayload;
  Map<String, dynamic>? lastApplyPayload;
  int applyCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<dynamic> getMyCode() async {
    if (error != null) throw _err;
    return codeResponse ?? <String, dynamic>{'code': 'ADA123'};
  }

  @override
  Future<ValidateCodeResponse> validateCode(Map<String, dynamic> data) async {
    lastValidatePayload = data;
    if (error != null) throw _err;
    return const ValidateCodeResponse(valid: true, referrerName: 'Ada');
  }

  @override
  Future<dynamic> applyCode(Map<String, dynamic> data) async {
    applyCallCount++;
    lastApplyPayload = data;
    if (error != null) throw _err;
    return applyResponse ?? <String, dynamic>{'referrerName': 'Ada'};
  }

  @override
  Future<ReferralStats> getStats() async {
    if (error != null) throw _err;
    return const ReferralStats(total: 3, pending: 1, completed: 2, remaining: 7);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeReferralService.${invocation.memberName}');
}

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
  group('getMyCode — savunmaci okuma', () {
    test('kod yanittan cikarilir', () async {
      final fake = _FakeReferralService(codeResponse: {'code': 'BERK42'});

      final result = await ReferralRepository(fake).getMyCode();

      expect(result.when(success: (d) => d, failure: (_) => null), 'BERK42');
    });

    test('kod alani YOKSA Failure — bos string dondurulup paylasilmasin', () async {
      // Kullanici bu kodu arkadasina gonderiyor; sessizce bos/yanlis bir sey
      // dondurmek davetin hic calismamasi demek.
      final fake = _FakeReferralService(codeResponse: <String, dynamic>{});

      final result = await ReferralRepository(fake).getMyCode();

      expect(result.isFailure, isTrue);
    });

    test('kod String degilse Failure', () async {
      final fake = _FakeReferralService(codeResponse: {'code': 12345});

      final result = await ReferralRepository(fake).getMyCode();

      expect(result.isFailure, isTrue);
    });
  });

  group('applyCode — odul yolu', () {
    test('kod payload olarak OLDUGU GIBI gider — istemci buyuk harfe cevirmez', () async {
      // Sunucu `.transform(v => v.toUpperCase())` yapiyor
      // (referral.validator.ts:4). Istemcide ikinci bir normalizasyon,
      // iki tarafin kurali ayrisirsa sessiz uyusmazlik yaratir.
      final fake = _FakeReferralService();

      await ReferralRepository(fake).applyCode('ada123');

      expect(fake.lastApplyPayload, {'code': 'ada123'});
    });

    test('referrerName camelCase okunur', () async {
      // Yanit alani camelCase (referral.routes.ts:73), istek alanlari snake_case.
      final fake = _FakeReferralService(applyResponse: {'referrerName': 'Berk'});

      final result = await ReferralRepository(fake).applyCode('BERK42');

      expect(result.when(success: (d) => d, failure: (_) => null), 'Berk');
    });

    test('snake_case referrer_name gelirse Failure — sessizce bos isim gosterilmesin', () async {
      final fake = _FakeReferralService(applyResponse: {'referrer_name': 'Berk'});

      final result = await ReferralRepository(fake).applyCode('BERK42');

      expect(result.isFailure, isTrue);
    });

    test('gecersiz kod ServerFailure olarak tasinir ve servis bir kez cagrilir', () async {
      // Odul yolunda sessiz tekrar, ayni daveti iki kez uygulamaya calismak demek.
      final fake = _FakeReferralService(
        error: _dio(DioExceptionType.badResponse,
            status: 400, body: {'error': {'code': 'INVALID_REFERRAL_CODE'}}),
      );

      final result = await ReferralRepository(fake).applyCode('YOK123');

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'INVALID_REFERRAL_CODE');
      expect(fake.applyCallCount, 1);
    });
  });

  group('validateCode / getStats', () {
    test('validateCode payload {code: ...} gonderir', () async {
      final fake = _FakeReferralService();

      await ReferralRepository(fake).validateCode('ADA123');

      expect(fake.lastValidatePayload, {'code': 'ADA123'});
    });

    test('istatistikler modele gecer', () async {
      final result = await ReferralRepository(_FakeReferralService()).getStats();

      final stats = result.when(success: (d) => d, failure: (_) => null)!;
      expect(stats.total, 3);
      expect(stats.remaining, 7);
    });

    test('ag hatasi Failure olur', () async {
      final fake = _FakeReferralService(error: _dio(DioExceptionType.connectionError));

      final result = await ReferralRepository(fake).getStats();

      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });
  });
}
