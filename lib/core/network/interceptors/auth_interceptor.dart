import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qulo_v2/core/network/log_manager.dart';
import 'package:qulo_v2/core/network/network_manager.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final VoidCallback? onForceLogout;
  final FlutterSecureStorage _storage;
  final Dio Function() _createRefreshDio;
  final Duration _retryBaseDelay;

  /// Ayni anda gelen 401'ler tek yenilemeyi paylasir.
  Future<String?>? _refreshInFlight;

  static const _maxRetries = 3;

  /// Yeni token'la tekrar gonderilen istegin isareti: o da 401 alirsa ikinci
  /// kez yenileme denenmez — yoksa yenile/tekrarla dongusu hic bitmezdi.
  static const _retriedKey = 'auth_retried';

  /// 401'in "oturum bitti" degil "kimlik bilgisi gecersiz" demek oldugu uclar.
  static const _noRefreshPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/social-login',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  AuthInterceptor(
    this._dio, {
    this.onForceLogout,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    Dio Function() createRefreshDio = NetworkManager.createRefreshDio,
    Duration retryBaseDelay = const Duration(seconds: 1),
  })  : _storage = storage,
        _createRefreshDio = createRefreshDio,
        _retryBaseDelay = retryBaseDelay;

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
    final options = err.requestOptions;
    final isAuthEndpoint = _noRefreshPaths.any((p) => options.path.endsWith(p));
    final alreadyRetried = options.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
      return handler.next(err);
    }

    final String? newToken;
    try {
      newToken = await _ensureRefreshed();
    } catch (e) {
      // Beklenmeyen hata (or. depolamaya yazilamadi): handler mutlaka
      // tamamlanmali, yoksa istek sonsuza kadar asili kalir.
      LogManager.instance.logInfo('AUTH', 'Refresh failed unexpectedly: $e');
      return handler.next(err);
    }
    if (newToken == null) {
      return handler.next(err);
    }

    try {
      options.headers['Authorization'] = 'Bearer $newToken';
      options.extra[_retriedKey] = true;
      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  Future<String?> _ensureRefreshed() => _refreshInFlight ??=
      _refreshWithRetry().whenComplete(() => _refreshInFlight = null);

  Future<String?> _refreshWithRetry() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      // Önceki force-logout sonrası storage boş — log gürültüsünü azalt,
      // idempotent forceLogout cascade'i zaten engelliyor.
      LogManager.instance.logInfo('AUTH', 'No refresh token, skip refresh');
      onForceLogout?.call();
      return null;
    }

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final refreshDio = _createRefreshDio();
        final response = await refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final data = response.data;
        final newAccess = data is Map ? data['accessToken'] as String? : null;
        final newRefresh = data is Map ? data['refreshToken'] as String? : null;

        if (newAccess == null || newRefresh == null) {
          LogManager.instance.logError(
            'POST',
            '/auth/refresh',
            response.statusCode,
            'Malformed token response — missing accessToken or refreshToken',
          );
          break;
        }

        await _storage.write(key: 'access_token', value: newAccess);
        await _storage.write(key: 'refresh_token', value: newRefresh);

        LogManager.instance.logInfo(
          'AUTH',
          'Token refreshed (attempt $attempt)',
        );
        return newAccess;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        String? errorCode;
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final errorMap = responseData['error'];
          if (errorMap is Map<String, dynamic>) {
            errorCode = errorMap['code'] as String?;
          }
        }

        if (errorCode == 'INVALID_TOKEN') {
          LogManager.instance.logError(
            'POST',
            '/auth/refresh',
            statusCode,
            'Refresh token revoked',
          );
          break;
        }

        LogManager.instance.logError(
          'POST',
          '/auth/refresh',
          statusCode,
          'Refresh attempt $attempt/$_maxRetries failed',
        );

        if (attempt < _maxRetries) {
          await Future.delayed(_retryBaseDelay * (1 << (attempt - 1))); // 1s, 2s, 4s
        }
      }
    }

    _forceLogout();
    return null;
  }

  void _forceLogout() {
    _storage.deleteAll();
    LogManager.instance.logInfo('AUTH', 'Force logout — all retries exhausted');
    onForceLogout?.call();
  }
}
