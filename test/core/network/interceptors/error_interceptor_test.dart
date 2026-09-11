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
