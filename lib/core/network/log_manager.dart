import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:dio/dio.dart';

class LogManager {
  LogManager._();
  static final LogManager instance = LogManager._();

  void logRequest(String method, String url) {
    if (kDebugMode) {
      debugPrint('→ $method $url');
    }
  }

  void logResponse(String method, String url, int? statusCode) {
    if (kDebugMode) {
      debugPrint('← $statusCode $method $url');
    }
  }

  void logError(String method, String url, int? statusCode, String? message) {
    if (kDebugMode) {
      debugPrint('✖ $statusCode $method $url ${message ?? ''}');
    }
  }

  void logInfo(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  Interceptor get dioLogInterceptor => PrettyDioLogger(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: kDebugMode,
        error: kDebugMode,
        compact: true,
        maxWidth: 90,
      );
}
