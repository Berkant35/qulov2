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

  /// Non-fatal'in tek kayit yolu `AnalyticsManager.logNonFatalError`
  /// (Crashlytics kaydi + baglam anahtari + analytics olayi). Burada ayrica
  /// `recordError` cagirmak her non-fatal'i Crashlytics'e iki kez yaziyordu.
  static void logError(Object error, [StackTrace? stack, String? reason]) {
    if (!kReleaseMode) {
      debugPrint('Error: $error${reason != null ? ' ($reason)' : ''}');
    }
    AnalyticsManager.instance.logNonFatalError(error, stack, context: reason);
  }

  static void setUser(String userId) {
    _crashlytics.setUserIdentifier(userId);
    AnalyticsManager.instance.setUserId(userId);
  }

  static void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }
}
