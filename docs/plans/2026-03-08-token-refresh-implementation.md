# Token Refresh & Startup Auth Validation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Invalid token durumunda 3 retry (backoff'lu) yapan, başarısız olunca sessiz logout eden, app açılışında token geçerliliğini doğrulayan auth sistemi.

**Architecture:** AuthInterceptor'ı Completer pattern ile yeniden yaz (concurrent 401 desteği), NetworkManager'a onForceLogout callback inject et, AuthNotifier'da hibrit token validation ekle.

**Tech Stack:** Flutter, Dio interceptors, Riverpod, FlutterSecureStorage, dart:convert (JWT decode)

---

### Task 1: AuthInterceptor — 3 Retry + Backoff + Completer + Force Logout

**Files:**
- Modify: `lib/core/network/interceptors/auth_interceptor.dart` (tümü yeniden yazılacak)

**Step 1: AuthInterceptor'ı yeniden yaz**

```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qulo_v2/core/config/env.dart';
import 'package:qulo_v2/core/network/log_manager.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final VoidCallback? onForceLogout;
  final _storage = const FlutterSecureStorage();

  Completer<String?>? _refreshCompleter;

  static const _maxRetries = 3;
  static const _noRefreshPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  AuthInterceptor(this._dio, {this.onForceLogout});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = _noRefreshPaths.any((p) => path.endsWith(p));

    if (err.response?.statusCode != 401 || isAuthEndpoint) {
      return handler.next(err);
    }

    // Try to get a fresh access token
    final newToken = await _ensureRefreshed();
    if (newToken == null) {
      return handler.next(err);
    }

    // Retry original request with new token
    try {
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  /// If a refresh is already in progress, wait for it.
  /// Otherwise, start a new refresh cycle.
  Future<String?> _ensureRefreshed() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    final result = await _refreshWithRetry();
    _refreshCompleter!.complete(result);
    _refreshCompleter = null;
    return result;
  }

  /// Attempt refresh up to [_maxRetries] times with backoff.
  /// Returns new access token on success, null on failure.
  Future<String?> _refreshWithRetry() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      _forceLogout();
      return null;
    }

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await Dio().post(
          '${Env.apiBaseUrl}/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final newAccess = response.data['accessToken'] as String;
        final newRefresh = response.data['refreshToken'] as String;
        await _storage.write(key: 'access_token', value: newAccess);
        await _storage.write(key: 'refresh_token', value: newRefresh);

        LogManager.instance.logInfo(
          'AUTH',
          'Token refreshed (attempt $attempt)',
        );
        return newAccess;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final errorCode = e.response?.data is Map
            ? (e.response!.data as Map)['error']?['code']
            : null;

        // INVALID_TOKEN means refresh token is revoked — no point retrying
        if (errorCode == 'INVALID_TOKEN') {
          LogManager.instance.logError(
            'POST', '/auth/refresh', statusCode, 'Refresh token revoked',
          );
          break;
        }

        LogManager.instance.logError(
          'POST',
          '/auth/refresh',
          statusCode,
          'Refresh attempt $attempt/$_maxRetries failed',
        );

        // Backoff before next attempt (skip on last attempt)
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    // All retries exhausted
    _forceLogout();
    return null;
  }

  void _forceLogout() {
    _storage.deleteAll();
    LogManager.instance.logInfo('AUTH', 'Force logout — all retries exhausted');
    onForceLogout?.call();
  }
}
```

**Step 2: Flutter analyze ile kontrol et**

Run: `dart analyze lib/core/network/interceptors/auth_interceptor.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/network/interceptors/auth_interceptor.dart
git commit -m "feat: auth interceptor with 3 retry, backoff, completer, force logout"
```

---

### Task 2: NetworkManager — onForceLogout Callback Injection

**Files:**
- Modify: `lib/core/network/network_manager.dart`

**Step 1: NetworkManager'a onForceLogout desteği ekle**

Singleton pattern'i koruyarak, `init` metodu ekle. Constructor'daki interceptor setup'ını `init`'e taşı.

```dart
import 'dart:io' show Platform;
import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';
import 'package:qulo_v2/core/config/env.dart';
import 'package:qulo_v2/core/network/interceptors/auth_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/error_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/log_interceptor.dart';
import 'package:qulo_v2/core/network/result.dart';

class NetworkManager {
  NetworkManager._();

  static final NetworkManager _instance = NetworkManager._();
  static NetworkManager get instance => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  bool _initialized = false;

  void init({VoidCallback? onForceLogout}) {
    if (_initialized) return;
    _initialized = true;

    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'x-app-platform': Platform.isIOS ? 'ios' : 'android',
      },
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(_dio, onForceLogout: onForceLogout),
      AppLogInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  // ... rest of methods (get, post, patch, etc.) unchanged ...
}
```

NOT: Mevcut tüm `get`, `post`, `put`, `patch`, `delete`, `upload` metodları aynen kalacak — sadece constructor → init dönüşümü yapılacak.

**Step 2: Flutter analyze ile kontrol et**

Run: `dart analyze lib/core/network/network_manager.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/network/network_manager.dart
git commit -m "feat: NetworkManager init with onForceLogout callback"
```

---

### Task 3: AuthNotifier — forceLogout + Hibrit Token Validation

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Step 1: forceLogout metodu ve hibrit _checkAuth ekle**

`_checkAuth` metodunu aşağıdakiyle değiştir ve `forceLogout` ekle:

```dart
// Mevcut import'lara ekle:
import 'dart:convert';
import 'package:qulo_v2/core/network/network_manager.dart';

// AuthNotifier class'ına ekle:

  Future<void> _checkAuth() async {
    try {
      final token = await _storage.read(key: 'access_token');
      final userId = await _storage.read(key: 'user_id');

      if (token == null || userId == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Check JWT expiry locally first
      if (_isTokenExpired(token)) {
        // Token expired — try refresh
        final refreshed = await _tryRefreshToken();
        if (!refreshed) {
          await _clearTokens();
          state = state.copyWith(status: AuthStatus.unauthenticated);
          return;
        }
      }

      // Token not expired (or refreshed) — validate with server
      try {
        await ref.read(userProvider.notifier).fetchMe();
        ErrorManager.setUser(userId);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userId: userId,
        );
      } catch (_) {
        // fetchMe failed (possibly 401 → interceptor will handle refresh)
        // If interceptor force-logged out, state is already unauthenticated
        if (state.status == AuthStatus.initial) {
          await _clearTokens();
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      // JWT base64url padding
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = map['exp'] as int?;
      if (exp == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Consider expired if less than 30 seconds remaining
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final dio = Dio();
      final response = await dio.post(
        '${Env.apiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = response.data['accessToken'] as String;
      final newRefresh = response.data['refreshToken'] as String;
      await _storage.write(key: 'access_token', value: newAccess);
      await _storage.write(key: 'refresh_token', value: newRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Called by AuthInterceptor when all refresh retries are exhausted.
  Future<void> forceLogout() async {
    // Tokens already cleared by interceptor — just update state
    try {
      await RevenueCatService.logOut();
    } catch (_) {}

    ref.invalidate(userProvider);
    ref.invalidate(discoverProvider);
    ref.invalidate(matchListProvider);
    ref.invalidate(diamondProvider);
    ref.invalidate(powerProvider);
    ref.invalidate(questionProvider);
    ref.invalidate(subscriptionProvider);
    ref.invalidate(notificationProvider);

    state = const AuthState(status: AuthStatus.unauthenticated);
  }
```

Ayrıca `import 'package:qulo_v2/core/config/env.dart';` ekle.

**Step 2: Flutter analyze ile kontrol et**

Run: `dart analyze lib/providers/auth_provider.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "feat: hybrid token validation + forceLogout in AuthNotifier"
```

---

### Task 4: main.dart — NetworkManager Init ile ForceLogout Bağlantısı

**Files:**
- Modify: `lib/main.dart`

**Step 1: ProviderContainer oluştur, NetworkManager.init çağır**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:qulo_v2/firebase_options.dart';
import 'package:qulo_v2/core/config/supabase_config.dart';
import 'package:qulo_v2/core/error/error_manager.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ErrorManager.init();
  await initSupabase();

  final container = ProviderContainer();

  NetworkManager.instance.init(
    onForceLogout: () {
      container.read(authProvider.notifier).forceLogout();
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QuloApp(),
    ),
  );
}
```

**Step 2: Flutter analyze ile kontrol et**

Run: `dart analyze lib/main.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire NetworkManager forceLogout to AuthNotifier via ProviderContainer"
```

---

### Task 5: Splash Screen — Auth Validation Bekleme

**Files:**
- Modify: `lib/features/splash/splash_screen.dart`

**Step 1: _waitForAuth'u sil, splash doğal akışta beklesin**

Splash'te özel bir şey yapmaya gerek yok — `_checkAuth` artık async olarak `/me` çağırıyor, `authProvider` state'i `initial` → `authenticated`/`unauthenticated` olarak değişiyor, GoRouter redirect bunu zaten dinliyor. Sadece `_waitForAuth` metodundaki boş listener'ı temizle:

```dart
  void _waitForAuth() {
    // Auth validation is handled by AuthNotifier._checkAuth
    // GoRouter redirect listens to authProvider state changes
    // No manual action needed here
  }
```

**Step 2: Flutter analyze**

Run: `dart analyze lib/features/splash/splash_screen.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/splash/splash_screen.dart
git commit -m "refactor: clean up splash waitForAuth — validation handled by AuthNotifier"
```

---

### Task 6: End-to-End Manuel Test

**Step 1: Normal akış testi**

1. `cd server && npm run dev` — backend'i başlat
2. `flutter run` — uygulamayı başlat
3. Login yap → discover ekranı açılmalı
4. App'i kapat, tekrar aç → splash → otomatik login (token valid)

**Step 2: Expired token testi**

1. Login yap
2. Server'da JWT_ACCESS_SECRET'ı geçici olarak değiştir → restart
3. App'te herhangi bir istek yap (discover'a geç)
4. Logda "Token refreshed (attempt 1)" görmelisin
5. Secret'ı geri al

**Step 3: Force logout testi**

1. Login yap
2. Supabase SQL Editor'da: `DELETE FROM refresh_tokens WHERE user_id = '<test-user-id>'`
3. App'te herhangi bir istek yap
4. Logda "Refresh token revoked" → "Force logout" görmelisin
5. Login ekranına yönlendirilmelisin

**Step 4: Commit (tüm değişikliklerin son hali)**

```bash
git add -A
git commit -m "feat: token refresh with 3 retry backoff, startup validation, force logout"
```
