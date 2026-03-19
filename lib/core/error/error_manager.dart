import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';

class ErrorManager {
  static final _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> init() async {
    FlutterError.onError = (details) {
      if (kReleaseMode) {
        _crashlytics.recordFlutterFatalError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kReleaseMode) {
        _crashlytics.recordError(error, stack, fatal: true);
      } else {
        debugPrint('Async error: $error\n$stack');
      }
      return true;
    };

    await _crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
  }

  static void logError(Object error, [StackTrace? stack, String? reason]) {
    if (kReleaseMode) {
      _crashlytics.recordError(error, stack, reason: reason);
    } else {
      debugPrint('Error: $error${reason != null ? ' ($reason)' : ''}');
    }

    // Forward to AnalyticsManager for breadcrumb tracking
    AnalyticsManager.instance.logNonFatalError(error, stack, context: reason);
  }

  static void setUser(String userId) {
    _crashlytics.setUserIdentifier(userId);
    AnalyticsManager.instance.setUserId(userId);
  }

  static void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }

  /// Log API errors with extended context
  static void logApiError({
    required String endpoint,
    required int? statusCode,
    required int responseTimeMs,
    Object? error,
    StackTrace? stack,
  }) {
    logError(
      error ?? 'API Error: $endpoint ($statusCode)',
      stack,
      'API: $endpoint',
    );
  }

  /// Log network errors
  static void logNetworkError({
    required String endpoint,
    required String errorType,
    required int durationMs,
    Object? error,
    StackTrace? stack,
  }) {
    logError(
      error ?? 'Network Error: $errorType on $endpoint',
      stack,
      'Network: $endpoint ($errorType)',
    );
  }
}
