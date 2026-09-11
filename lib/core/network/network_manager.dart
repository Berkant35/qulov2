import 'dart:io' show Platform;
import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:qulo_v2/core/config/env.dart';
import 'package:qulo_v2/core/network/interceptors/accept_language_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/app_version_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/auth_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/error_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/idempotency_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/log_interceptor.dart';
import 'package:qulo_v2/core/network/interceptors/session_interceptor.dart';
import 'package:qulo_v2/core/network/result.dart';

class NetworkManager {
  NetworkManager._();

  static final NetworkManager _instance = NetworkManager._();
  static NetworkManager get instance => _instance;

  bool _initialized = false;

  late final Dio _dio;
  Dio get dio => _dio;

  /// Settable force-logout callback.
  /// Set from app.dart after ProviderScope is available.
  VoidCallback? onForceLogout;

  void init({VoidCallback? onForceLogout}) {
    if (_initialized) return;
    _initialized = true;

    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      maxRedirects: 3,
      headers: {
        'Content-Type': 'application/json',
        'x-app-platform': Platform.isIOS ? 'ios' : 'android',
      },
    ));

    // Store callback if provided at init time
    if (onForceLogout != null) {
      this.onForceLogout = onForceLogout;
    }

    _dio.interceptors.addAll([
      SessionInterceptor(),
      AcceptLanguageInterceptor(),
      AppVersionInterceptor(),
      IdempotencyInterceptor(),
      AuthInterceptor(_dio, onForceLogout: () => this.onForceLogout?.call()),
      AppLogInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  // ─── Manual Methods (Result<T>) ───

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) =>
      guard<T>(() => _dio.get(path, queryParameters: queryParameters), parser);

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) =>
      guard<T>(() => _dio.post(path, data: data), parser);

  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) =>
      guard<T>(() => _dio.put(path, data: data), parser);

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? parser,
  }) =>
      guard<T>(() => _dio.delete(path, data: data), parser);

  Future<Result<T>> upload<T>(
    String path, {
    required FormData data,
    T Function(dynamic json)? parser,
  }) =>
      guard<T>(() => _dio.post(path, data: data), parser);

  /// Manuel metodlarin ortak sonuc/hata yolu: Dio hatasi → `toAppFailure()`,
  /// digeri (parser ya da cast dahil) → `UnknownFailure`. Parser verilmezse ham
  /// govde `T`'ye cast edilir. Saf oldugu icin testte interceptor zinciri
  /// olmadan dogrudan cagrilir.
  @visibleForTesting
  static Future<Result<T>> guard<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic json)? parser,
  ) async {
    try {
      final response = await request();
      return Success(parser != null ? parser(response.data) : response.data as T);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  /// Creates a Dio instance for token refresh requests.
  /// Includes base URL, timeouts, and logging — but NO auth interceptor
  /// to avoid infinite 401 loops.
  static Dio createRefreshDio() {
    return Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ))
      ..interceptors.add(AppLogInterceptor());
  }
}
