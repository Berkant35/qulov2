import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/interceptors/auth_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/error_interceptor.dart';

import '../../../helpers/fake_secure_storage.dart';
import '../../../helpers/scripted_http_adapter.dart';

/// Crashlytics'e hangi API hatasinin gidecegi.
///
/// Gercek Dio + uretimdeki sira (AuthInterceptor → ErrorInterceptor): token
/// yenileme sonrasi tekrar gonderim `_dio.fetch` ile tum zinciri yeniden
/// gezer, ayni hata ic ve dis zincirde iki kez ErrorInterceptor'dan gecer.
void main() {
  test('sunucu hatasi (500) bir kez raporlanir, sebep ucu tasir', () async {
    final h = _Harness(api: _status(500));

    await _expectStatus(h.dio.get('/me'), 500);

    expect(h.reasons, ['API GET /me']);
  });

  test('504 raporlanir — sunucu kesintisinin mobildeki tek sinyali', () async {
    final h = _Harness(api: _status(504));

    await _expectStatus(h.dio.get('/discover'), 504);

    expect(h.reasons, ['API GET /discover']);
  });

  group('raporlanmaz', () {
    test('giris ucunda 401 (yanlis sifre) — beklenen kullanici hatasi', () async {
      final h = _Harness(api: _status(401));

      await _expectStatus(h.dio.post('/auth/login'), 401);

      expect(h.reasons, isEmpty);
    });

    test('yenileme de reddedilince 401 — oturum yolu kendisi yonetir', () async {
      final h = _Harness(api: _status(401), refresh: _status(401));

      await _expectStatus(h.dio.get('/me'), 401);

      expect(h.reasons, isEmpty);
    });

    test('iptal edilen istek', () async {
      final h = _Harness(
        api: ScriptedHttpAdapter((o) async => throw DioException(
              requestOptions: o,
              type: DioExceptionType.cancel,
            )),
      );

      await expectLater(h.dio.get('/me'), throwsA(isA<DioException>()));

      expect(h.reasons, isEmpty);
    });

    test('presence ucu sessiz', () async {
      final h = _Harness(api: _status(500));

      await _expectStatus(h.dio.post('/users/me/presence'), 500);

      expect(h.reasons, isEmpty);
    });

    // Sozlesme: imzalayici yokken 503, istemci anon baglantiyla surer; her
    // one gelista tekrar denendigi icin raporlansa Crashlytics dolardi.
    test('realtime token ucu 503 REALTIME_TOKEN_UNAVAILABLE', () async {
      final h = _Harness(api: _coded(503, 'REALTIME_TOKEN_UNAVAILABLE'));

      await _expectStatus(h.dio.post('/realtime/token'), 503);

      expect(h.reasons, isEmpty);
    });

    for (final (status, code, path) in [
      (400, 'PROFILE_INCOMPLETE', '/discover'), // Discover: konum yok
      (403, 'DAILY_LIMIT_EXCEEDED', '/discover/swipe'),
      (403, 'INSUFFICIENT_DIAMONDS', '/quiz/power'),
      (403, 'EMAIL_VERIFICATION_REQUIRED', '/matches'),
    ]) {
      test('iş kuralı yanıtı: $status $code', () async {
        final h = _Harness(api: _coded(status, code));

        await _expectStatus(h.dio.get(path), status);

        expect(h.reasons, isEmpty);
      });
    }
  });

  group('raporlanmaya devam eder', () {
    for (final (status, code) in [
      (400, 'VALIDATION_ERROR'), // istemci yanlış gövde yolluyor
      (403, 'FORBIDDEN'),
      (404, 'USER_NOT_FOUND'),
      (429, 'RATE_LIMITED'), // döngüye giren istek
      (400, 'BILINMEYEN_YENI_KOD'), // listede olmayan kod
      (500, 'INSUFFICIENT_DIAMONDS'), // iş kodu ama 5xx → sunucu hatası
    ]) {
      test('$status $code', () async {
        final h = _Harness(api: _coded(status, code));

        await _expectStatus(h.dio.get('/x'), status);

        expect(h.reasons, ['API GET /x']);
      });
    }

    test('realtime token ucunda baska 5xx (imzalama hatasi) raporlanir', () async {
      final h = _Harness(api: _coded(500, 'SERVER_ERROR'));

      await _expectStatus(h.dio.post('/realtime/token'), 500);

      expect(h.reasons, ['API POST /realtime/token']);
    });

    test('baska uctan gelen 503 REALTIME_TOKEN_UNAVAILABLE raporlanir', () async {
      final h = _Harness(api: _coded(503, 'REALTIME_TOKEN_UNAVAILABLE'));

      await _expectStatus(h.dio.get('/x'), 503);

      expect(h.reasons, ['API GET /x']);
    });

    test('gövdesinde kod olmayan 403', () async {
      final h = _Harness(api: _status(403));

      await _expectStatus(h.dio.get('/x'), 403);

      expect(h.reasons, ['API GET /x']);
    });

    test('bağlantı zaman aşımı', () async {
      final h = _Harness(
        api: ScriptedHttpAdapter((o) async => throw DioException(
              requestOptions: o,
              type: DioExceptionType.connectionTimeout,
            )),
      );

      await expectLater(h.dio.get('/x'), throwsA(isA<DioException>()));

      expect(h.reasons, ['API GET /x']);
    });

    test('bağlantı hatası', () async {
      final h = _Harness(
        api: ScriptedHttpAdapter((o) async => throw DioException(
              requestOptions: o,
              type: DioExceptionType.connectionError,
            )),
      );

      await expectLater(h.dio.get('/x'), throwsA(isA<DioException>()));

      expect(h.reasons, ['API GET /x']);
    });
  });

  test('YENI token ile de 401 → raporlanir (sunucu taze token\'i reddediyor), tek sefer', () async {
    final h = _Harness(api: _status(401));

    await _expectStatus(h.dio.get('/me'), 401);

    expect(h.reasons, ['API GET /me']);
  });

  test('yenileme sonrasi tekrar da 500 alirsa TEK rapor (ic + dis zincir)', () async {
    var calls = 0;
    final h = _Harness(
      api: ScriptedHttpAdapter(
        (_) async => jsonResponse(++calls == 1 ? 401 : 500, {'error': 'x'}),
      ),
    );

    await _expectStatus(h.dio.get('/me'), 500);

    expect(calls, 2, reason: 'tekrar gonderim gerceklesmeli');
    expect(h.reasons, ['API GET /me']);
  });
}

Future<void> _expectStatus(Future<Response<dynamic>> call, int status) async {
  await expectLater(
    call,
    throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', status)),
  );
}

ScriptedHttpAdapter _status(int status) =>
    ScriptedHttpAdapter((_) async => jsonResponse(status, {'error': 'x'}));

/// qulo-server `AppError` gövdesi: `{error: {code, message}}`.
ScriptedHttpAdapter _coded(int status, String code) => ScriptedHttpAdapter(
      (_) async => jsonResponse(status, {
        'error': {'code': code, 'message': code},
      }),
    );

class _Harness {
  _Harness({required ScriptedHttpAdapter api, ScriptedHttpAdapter? refresh}) {
    final refreshAdapter = refresh ??
        ScriptedHttpAdapter(
          (_) async => jsonResponse(200, {'accessToken': 'new', 'refreshToken': 'new-r'}),
        );
    dio = scriptedDio(api);
    dio.interceptors.addAll([
      AuthInterceptor(
        dio,
        storage: FakeSecureStorage({'access_token': 'old', 'refresh_token': 'old-r'}),
        createRefreshDio: () => scriptedDio(refreshAdapter),
        retryBaseDelay: Duration.zero,
      ),
      ErrorInterceptor(report: (_, [__, reason]) => reasons.add(reason)),
    ]);
  }

  late final Dio dio;
  final reasons = <String?>[];
}
