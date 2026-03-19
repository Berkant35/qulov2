import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qulo_v2/core/network/log_manager.dart';
import 'package:qulo_v2/core/network/network_manager.dart';

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

    final newToken = await _ensureRefreshed();
    if (newToken == null) {
      return handler.next(err);
    }

    try {
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

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

  Future<String?> _refreshWithRetry() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      _forceLogout();
      return null;
    }

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final refreshDio = NetworkManager.createRefreshDio();
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
          final delayMs = 1000 * (1 << (attempt - 1)); // 1s, 2s, 4s
          await Future.delayed(Duration(milliseconds: delayMs));
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
