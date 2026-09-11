import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/notification_manager.dart';
import 'package:qulo_v2/core/services/presence_manager.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/auth_repository.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/deep_link_provider.dart';

import '../helpers/scripted_http_adapter.dart';

/// Oturum durumu — acilis (splash → checkAuth), giris hatasi, cikis.
///
/// Basari yollari (checkAuth/login authenticated'a gecis) burada YOK:
/// `ErrorManager.setUser` Crashlytics'e dokunuyor, testte Firebase yok.
/// Access token 15 dk yasiyor (qulo-server `utils/jwt.ts`), refresh 30 gun —
/// yani acilislarin cogu "suresi dolmus token → yenile" yolundan gecer.
void main() {
  group('checkAuth — acilis', () {
    test('token yoksa unauthenticated, sunucuya gidilmez', () async {
      final h = _Harness();

      await h.checkAuth();

      expect(h.state.status, AuthStatus.unauthenticated);
      expect(h.me.calls, 0);
    });

    test('hesap banliysa banned ve oturum silinir', () async {
      final h = _Harness(
        stored: _session(),
        me: const Failure(ServerFailure(code: 'ACCOUNT_BANNED', statusCode: 403)),
      );

      await h.checkAuth();

      expect(h.state.status, AuthStatus.banned);
      expect(await h.stored(), isEmpty);
    });

    test('sunucu oturumu reddederse (401) oturum silinir', () async {
      final h = _Harness(stored: _session(), me: const Failure(UnauthorizedFailure()));

      await h.checkAuth();

      expect(h.state.status, AuthStatus.unauthenticated);
      expect(await h.stored(), isEmpty);
    });

    for (final failure in <AppFailure>[
      const NetworkFailure(),
      const TimeoutFailure(),
      const ServerFailure(code: 'SERVER_ERROR', statusCode: 502),
    ]) {
      test('gecici hata (${failure.runtimeType}) oturumu SILMEZ', () async {
        // Eskiden her hata token'lari siliyordu: agsiz acilis ya da Railway
        // deploy anindaki 502, 30 gunluk oturumu kaybettiriyordu.
        final session = _session();
        final h = _Harness(stored: session, me: Failure(failure));

        await h.checkAuth();

        expect(h.state.status, AuthStatus.unauthenticated);
        expect(await h.stored(), session);
      });
    }
  });

  group('checkAuth — suresi dolmus access token', () {
    test('yenileme basarili → yeni token\'lar yazilir, sonra profil istenir', () async {
      final h = _Harness(
        stored: _session(expired: true),
        refresh: ScriptedHttpAdapter(
            (_) async => jsonResponse(200, {'accessToken': 'new', 'refreshToken': 'new-r'})),
        me: const Failure(NetworkFailure()),
      );

      await h.checkAuth();

      expect(h.refresh.requests.single.data, {'refreshToken': 'r1'});
      final stored = await h.stored();
      expect(stored['access_token'], 'new');
      expect(stored['refresh_token'], 'new-r');
      expect(h.me.calls, 1);
    });

    test('refresh token gecersiz (401 INVALID_TOKEN) → oturum silinir, profil istenmez', () async {
      final h = _Harness(
        stored: _session(expired: true),
        refresh: ScriptedHttpAdapter((_) async => jsonResponse(401, {
              'error': {'code': 'INVALID_TOKEN'},
            })),
      );

      await h.checkAuth();

      expect(h.state.status, AuthStatus.unauthenticated);
      expect(await h.stored(), isEmpty);
      expect(h.me.calls, 0);
    });

    test('yenilemede ag hatasi → oturum KORUNUR', () async {
      final session = _session(expired: true);
      final h = _Harness(
        stored: session,
        refresh: ScriptedHttpAdapter((o) async => throw DioException(
              requestOptions: o,
              type: DioExceptionType.connectionError,
            )),
      );

      await h.checkAuth();

      expect(h.state.status, AuthStatus.unauthenticated);
      expect(await h.stored(), session);
      expect(h.me.calls, 0);
    });

    test('yenilemede 503 → oturum KORUNUR', () async {
      final session = _session(expired: true);
      final h = _Harness(
        stored: session,
        refresh: ScriptedHttpAdapter((_) async => jsonResponse(503, {'error': 'down'})),
      );

      await h.checkAuth();

      expect(await h.stored(), session);
    });

    test('refresh token yoksa oturum silinir, yenileme denenmez', () async {
      final h = _Harness(stored: {
        'access_token': _jwt(DateTime.now().subtract(const Duration(hours: 1))),
        'user_id': 'u1',
      });

      await h.checkAuth();

      expect(h.state.status, AuthStatus.unauthenticated);
      expect(await h.stored(), isEmpty);
      expect(h.refresh.requests, isEmpty);
    });
  });

  group('login — hata yollari', () {
    test('yanlis sifre: hata tasinir, token yazilmaz, durum degismez', () async {
      final h = _Harness(
        auth: _FakeAuthRepository(
          loginResult: const Failure(ServerFailure(code: 'INVALID_CREDENTIALS', statusCode: 401)),
        ),
      );

      await h.notifier.login(email: 'a@b.c', password: 'yanlis');

      expect(h.state.status, AuthStatus.initial);
      expect(h.state.isLoading, isFalse);
      expect((h.state.failure as ServerFailure).code, 'INVALID_CREDENTIALS');
      expect(await h.stored(), isEmpty);
    });

    test('ACCOUNT_BANNED → banned', () async {
      final h = _Harness(
        auth: _FakeAuthRepository(
          loginResult: const Failure(ServerFailure(code: 'ACCOUNT_BANNED', statusCode: 403)),
        ),
      );

      await h.notifier.login(email: 'a@b.c', password: 'x');

      expect(h.state.status, AuthStatus.banned);
    });
  });

  group('logout', () {
    test('refresh token sunucuya gider, yerel oturum temizlenir', () async {
      final h = _Harness(stored: _session(), initial: AuthStatus.authenticated);
      h.container.read(pendingDeepLinkProvider.notifier).state = '/chat/m1';

      await h.notifier.logout();

      expect(h.auth.lastLogoutRefreshToken, 'r1');
      expect(await h.stored(), isEmpty);
      expect(h.presence.stopCalls, 1);
      expect(h.notifications.disposeCalls, 1);
      expect(h.state.status, AuthStatus.unauthenticated);
      expect(h.container.read(pendingDeepLinkProvider), isNull,
          reason: 'bekleyen link sonraki kullanicinin oturumunda acilmamali');
    });

    test('sunucu logout hatasi yerel cikisi durdurmaz', () async {
      final h = _Harness(
        stored: _session(),
        initial: AuthStatus.authenticated,
        auth: _FakeAuthRepository(logoutResult: const Failure(NetworkFailure())),
      );

      await h.notifier.logout();

      expect(await h.stored(), isEmpty);
      expect(h.state.status, AuthStatus.unauthenticated);
    });
  });

  group('forceLogout — interceptor 401 zinciri', () {
    test('oturumu kapatir; presence durdurulmaz, duraklatilir (offline cagrisi yok)', () async {
      final h = _Harness(stored: _session(), initial: AuthStatus.authenticated);

      await h.notifier.forceLogout();

      expect(h.state.status, AuthStatus.unauthenticated);
      expect(h.presence.pauseCalls, 1);
      expect(h.presence.stopCalls, 0);
      expect(h.notifications.disposeCalls, 1);
    });

    test('zaten unauthenticated ise yan etki yok — paralel 401 kaskadi', () async {
      final h = _Harness(initial: AuthStatus.unauthenticated);

      await h.notifier.forceLogout();
      await h.notifier.forceLogout();

      expect(h.presence.pauseCalls, 0);
      expect(h.notifications.disposeCalls, 0);
    });
  });
}

String _jwt(DateTime exp) {
  String part(Map<String, Object> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'exp': exp.millisecondsSinceEpoch ~/ 1000})}.sig';
}

Map<String, String> _session({bool expired = false}) => {
      'access_token': _jwt(DateTime.now().add(Duration(hours: expired ? -1 : 1))),
      'refresh_token': 'r1',
      'user_id': 'u1',
    };

class _SeededAuthNotifier extends AuthNotifier {
  _SeededAuthNotifier(this._status);
  final AuthStatus _status;

  @override
  AuthState build() => AuthState(status: _status);
}

class _Harness {
  _Harness({
    Map<String, String> stored = const {},
    Result<UserModel> me = const Failure(NetworkFailure()),
    _FakeAuthRepository? auth,
    ScriptedHttpAdapter? refresh,
    AuthStatus initial = AuthStatus.initial,
  })  : me = _MeRepository(me),
        auth = auth ?? _FakeAuthRepository(),
        refresh = refresh ?? ScriptedHttpAdapter((_) async => jsonResponse(500, {})) {
    FlutterSecureStorage.setMockInitialValues({...stored});
    container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _SeededAuthNotifier(initial)),
      userRepositoryProvider.overrideWithValue(this.me),
      authRepositoryProvider.overrideWithValue(this.auth),
      presenceManagerProvider.overrideWithValue(presence),
      notificationManagerProvider.overrideWithValue(notifications),
      refreshDioFactoryProvider.overrideWithValue(() => scriptedDio(this.refresh)),
    ]);
    addTearDown(container.dispose);
  }

  final _MeRepository me;
  final _FakeAuthRepository auth;
  final ScriptedHttpAdapter refresh;
  final presence = _FakePresence();
  final notifications = _FakeNotifications();
  late final ProviderContainer container;

  AuthNotifier get notifier => container.read(authProvider.notifier);
  AuthState get state => container.read(authProvider);
  Future<void> checkAuth() => notifier.checkAuth();
  Future<Map<String, String>> stored() => const FlutterSecureStorage().readAll();
}

class _MeRepository implements UserRepository {
  _MeRepository(this.result);

  final Result<UserModel> result;
  int calls = 0;

  @override
  Future<Result<UserModel>> getMe() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_MeRepository.${invocation.memberName}');
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.loginResult, this.logoutResult = const Success(null)});

  final Result<AuthTokens>? loginResult;
  final Result<void> logoutResult;
  String? lastLogoutRefreshToken;

  @override
  Future<Result<AuthTokens>> login({required String email, required String password}) async =>
      loginResult!;

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    lastLogoutRefreshToken = refreshToken;
    return logoutResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeAuthRepository.${invocation.memberName}');
}

class _FakePresence implements PresenceManager {
  int pauseCalls = 0;
  int stopCalls = 0;

  @override
  void pause() => pauseCalls++;

  @override
  Future<void> stop() async => stopCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakePresence.${invocation.memberName}');
}

class _FakeNotifications implements NotificationManager {
  int disposeCalls = 0;

  @override
  void dispose() => disposeCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNotifications.${invocation.memberName}');
}
