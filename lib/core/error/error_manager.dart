import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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
  }

  static void setUser(String userId) {
    _crashlytics.setUserIdentifier(userId);
  }

  static void setCustomKey(String key, Object value) {
    _crashlytics.setCustomKey(key, value);
  }
}
