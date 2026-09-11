import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/interceptors/auth_interceptor.dart';

import '../../../helpers/scripted_http_adapter.dart';

/// Oturum yenileme — her API cagrisinin arkasindaki yol.
///
/// Gercek Dio + senaryolu adapter: tekrar gonderim `_dio.fetch` ile tum
/// interceptor zincirinden yeniden gectigi icin (uretimdeki gibi) ancak gercek
/// Dio ile dogru sinanir. Sunucu sozlesmesi: `POST /auth/refresh`
/// `{refreshToken}` → `{accessToken, refreshToken}` (qulo-server
/// `auth.service.ts` → `refresh`), gecersizse 401 `INVALID_TOKEN`.
void main() {
  test('saklanan access token Bearer olarak eklenir', () async {
    final h = _Harness(stored: {'access_token': 'old'}, api: _ok());

    await h.dio.get('/me');

    expect(h.api.sentAuthHeaders.single, 'Bearer old');
  });

  test('token yoksa Authorization basligi eklenmez', () async {
    final h = _Harness(stored: {}, api: _ok());

    await h.dio.get('/app/config');

    expect(h.api.sentAuthHeaders.single, isNull);
  });

  group('401 → yenile → tekrarla', () {
    test('yeni token ile tekrar gonderilir ve basarili yanit doner', () async {
      final h = _Harness(stored: _session, api: _acceptsOnly('new'), refresh: _rotates());

      final response = await h.dio.get('/me');

      expect(response.data, {'ok': true});
      expect(h.api.sentAuthHeaders, ['Bearer old', 'Bearer new']);
    });

    test('yenileme istegi sozlesmeye uyar ve iki token da donusturulur', () async {
      final h = _Harness(stored: _session, api: _acceptsOnly('new'), refresh: _rotates());

      await h.dio.get('/me');

      final call = h.refresh.requests.single;
      expect(call.path, '/auth/refresh');
      expect(call.data, {'refreshToken': 'old-r'});
      expect(h.storage.values['access_token'], 'new');
      expect(h.storage.values['refresh_token'], 'new-r',
          reason: 'sunucu eski refresh token satirini siliyor; saklanmazsa sonraki yenileme INVALID_TOKEN alir');
    });

    test('ayni anda gelen iki 401 TEK yenilemeyi paylasir', () async {
      // Refresh token tek kullanimlik (rotasyon): ikinci paralel yenileme
      // silinmis token'la gider ve kullaniciyi disari atardi.
      final gate = Completer<void>();
      final h = _Harness(
        stored: _session,
        api: _acceptsOnly('new'),
        refresh: ScriptedHttpAdapter((_) async {
          await gate.future;
          return jsonResponse(200, {'accessToken': 'new', 'refreshToken': 'new-r'});
        }),
      );

      final both = Future.wait([h.dio.get('/a'), h.dio.get('/b')]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      gate.complete();
      final responses = await both;

      expect(h.refresh.requests, hasLength(1));
      expect(responses.map((r) => r.data), [
        {'ok': true},
        {'ok': true},
      ]);
    });
  });

  group('yenileme basarisiz → oturum kapanir', () {
    test('INVALID_TOKEN: tekrar denenmez, depo temizlenir, cikis bir kez', () async {
      final h = _Harness(
        stored: _session,
        api: _acceptsOnly('new'),
        refresh: ScriptedHttpAdapter((_) async => jsonResponse(401, _error('INVALID_TOKEN'))),
      );

      await _expectStatus(h.dio.get('/me'), 401);

      expect(h.refresh.requests, hasLength(1));
      expect(h.storage.values, isEmpty);
      expect(h.forceLogoutCount, 1);
    });

    test('ag hatasi: uc denemeden sonra cikis', () async {
      final h = _Harness(
        stored: _session,
        api: _acceptsOnly('new'),
        refresh: ScriptedHttpAdapter((o) async => throw DioException(
              requestOptions: o,
              type: DioExceptionType.connectionError,
            )),
      );

      await _expectStatus(h.dio.get('/me'), 401);

      expect(h.refresh.requests, hasLength(3));
      expect(h.forceLogoutCount, 1);
    });

    test('bozuk yanit (refreshToken yok): tek denemede cikis', () async {
      final h = _Harness(
        stored: _session,
        api: _acceptsOnly('new'),
        refresh: ScriptedHttpAdapter((_) async => jsonResponse(200, {'accessToken': 'new'})),
      );

      await _expectStatus(h.dio.get('/me'), 401);

      expect(h.refresh.requests, hasLength(1));
      expect(h.forceLogoutCount, 1);
    });

    test('refresh token yoksa yenileme hic denenmez, cikis cagrilir', () async {
      final h = _Harness(stored: {'access_token': 'old'}, api: _acceptsOnly('new'));

      await _expectStatus(h.dio.get('/me'), 401);

      expect(h.refreshDioCreated, 0);
      expect(h.forceLogoutCount, 1);
    });
  });

  group('yenileme TETIKLENMEZ', () {
    // Bu uclarda 401 "kimlik bilgisi gecersiz" demek. Sosyal giris eskiden
    // listede yoktu: hatali Google/Apple token'i (sunucu 401 INVALID_TOKEN /
    // SOCIAL_AUTH_FAILED) yenileme ve zorla cikis yolunu calistiriyordu.
    for (final path in ['/auth/login', '/auth/register', '/auth/social-login']) {
      test('$path 401 aldiginda', () async {
        final h = _Harness(stored: _session, api: _acceptsOnly('never'), refresh: _rotates());

        await _expectStatus(h.dio.post(path), 401);

        expect(h.refreshDioCreated, 0);
        expect(h.forceLogoutCount, 0);
      });
    }

    for (final status in [403, 500]) {
      test('401 disi hata ($status)', () async {
        final h = _Harness(
          stored: _session,
          api: ScriptedHttpAdapter((_) async => jsonResponse(status, _error('X'))),
          refresh: _rotates(),
        );

        await _expectStatus(h.dio.get('/me'), status);

        expect(h.refreshDioCreated, 0);
      });
    }
  });

  group('dayaniklilik', () {
    test('yeni token ile de 401 donerse ikinci yenileme YOK — dongu yok', () async {
      // Ornek: kimlik dogrulamasi token disinda bir sebeple reddediliyor.
      final h = _Harness(stored: _session, api: _acceptsOnly('never'), refresh: _rotates());

      await _expectStatus(h.dio.get('/me').timeout(const Duration(seconds: 2)), 401);

      expect(h.refresh.requests, hasLength(1));
      expect(h.api.requests, hasLength(2));
    });

    test('depolamaya yazilamazsa istek asili kalmaz, hatayla biter', () async {
      final h = _Harness(stored: _session, api: _acceptsOnly('new'), refresh: _rotates())
        ..storage.failWrites = true;

      await _expectStatus(h.dio.get('/me').timeout(const Duration(seconds: 2)), 401);
    });
  });
}

const _session = {'access_token': 'old', 'refresh_token': 'old-r'};

Future<void> _expectStatus(Future<Response<dynamic>> call, int status) async {
  await expectLater(
    call,
    throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', status)),
  );
}

Map<String, dynamic> _error(String code) => {
      'error': {'code': code},
    };

ScriptedHttpAdapter _ok() => ScriptedHttpAdapter((_) async => jsonResponse(200, {'ok': true}));

/// Yalnizca `Bearer <token>` ile gelen istegi kabul eder, gerisine 401.
ScriptedHttpAdapter _acceptsOnly(String token) => ScriptedHttpAdapter((o) async =>
    o.headers['Authorization'] == 'Bearer $token'
        ? jsonResponse(200, {'ok': true})
        : jsonResponse(401, _error('TOKEN_EXPIRED')));

ScriptedHttpAdapter _rotates() => ScriptedHttpAdapter(
    (_) async => jsonResponse(200, {'accessToken': 'new', 'refreshToken': 'new-r'}));

class _Harness {
  _Harness({
    required Map<String, String> stored,
    required this.api,
    ScriptedHttpAdapter? refresh,
  })  : refresh = refresh ?? _rotates(),
        storage = _FakeStorage(stored) {
    dio = scriptedDio(api);
    dio.interceptors.add(AuthInterceptor(
      dio,
      onForceLogout: () => forceLogoutCount++,
      storage: storage,
      createRefreshDio: () {
        refreshDioCreated++;
        return scriptedDio(this.refresh);
      },
      retryBaseDelay: Duration.zero,
    ));
  }

  final ScriptedHttpAdapter api;
  final ScriptedHttpAdapter refresh;
  final _FakeStorage storage;
  late final Dio dio;
  int forceLogoutCount = 0;
  int refreshDioCreated = 0;
}

/// Bellek-ici guvenli depo. Interceptor yalnizca read/write/deleteAll
/// kullaniyor; gerisi noSuchMethod ile patlar.
class _FakeStorage implements FlutterSecureStorage {
  _FakeStorage(Map<String, String> initial) : values = {...initial};

  final Map<String, String> values;
  bool failWrites = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #read:
        return Future<String?>.value(values[key]);
      case #write:
        if (failWrites) {
          return Future<void>.error(PlatformException(code: 'errSecInteractionNotAllowed'));
        }
        values[key!] = invocation.namedArguments[#value] as String;
        return Future<void>.value();
      case #deleteAll:
        values.clear();
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}
