import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:qulo_v2/core/services/analytics_breadcrumb.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';

class AnalyticsManager {
  AnalyticsManager._();
  static final AnalyticsManager instance = AnalyticsManager._();

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  final BreadcrumbQueue _breadcrumbs = BreadcrumbQueue(maxSize: 30);

  bool _initialized = false;
  DateTime? _sessionStart;
  DateTime? _backgroundStart;

  Future<void> init() async {
    if (_initialized) return;
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _sessionStart = DateTime.now();
    _initialized = true;

    await _analytics.setAnalyticsCollectionEnabled(kReleaseMode);
  }

  // ─── Core Event Logging ───

  void logEvent(String name, {Map<String, Object>? params}) {
    if (!_initialized) return;

    _analytics.logEvent(name: name, parameters: params);

    _crashlytics.log('EVENT: $name${params != null ? ' $params' : ''}');

    _breadcrumbs.add(BreadcrumbEntry(name, params, DateTime.now()));

    _crashlytics.setCustomKey('last_action', name);
    _crashlytics.setCustomKey('breadcrumb_trail', _breadcrumbs.getTrailSummary());

    if (kDebugMode) {
      debugPrint('[Analytics] $name${params != null ? ' | $params' : ''}');
    }
  }

  // ─── Screen Tracking ───

  void logScreenView(String screenName, {String? screenClass}) {
    if (!_initialized) return;

    _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );

    _crashlytics.setCustomKey('last_screen', screenName);
    _crashlytics.log('SCREEN: $screenName');
    _breadcrumbs.add(BreadcrumbEntry('screen_view:$screenName', null, DateTime.now()));

    if (kDebugMode) {
      debugPrint('[Analytics] Screen: $screenName');
    }
  }

  // ─── User Identity ───

  void setUserId(String? userId) {
    if (!_initialized) return;
    _analytics.setUserId(id: userId);
    if (userId != null) {
      _crashlytics.setUserIdentifier(userId);
    }
  }

  // ─── User Properties ───

  void setUserProperty(String name, String? value) {
    if (!_initialized) return;
    _analytics.setUserProperty(name: name, value: value);
    if (value != null) {
      _crashlytics.setCustomKey('up_$name', value);
    }
  }

  void updateUserProperties({
    String? subscriptionTier,
    String? diamondBalance,
    String? gender,
    String? ageRange,
    String? city,
    String? profileCompletion,
    String? totalMatches,
    String? totalMessagesSent,
    String? questionsCount,
    String? daysSinceRegister,
    String? hasPassport,
    String? notificationEnabled,
    String? appVersion,
    String? onboardingCompleted,
    String? photoCount,
  }) {
    if (subscriptionTier != null) setUserProperty('subscription_tier', subscriptionTier);
    if (diamondBalance != null) setUserProperty('diamond_balance', diamondBalance);
    if (gender != null) setUserProperty('gender', gender);
    if (ageRange != null) setUserProperty('age_range', ageRange);
    if (city != null) setUserProperty('city', city);
    if (profileCompletion != null) setUserProperty('profile_completion', profileCompletion);
    if (totalMatches != null) setUserProperty('total_matches', totalMatches);
    if (totalMessagesSent != null) setUserProperty('total_messages_sent', totalMessagesSent);
    if (questionsCount != null) setUserProperty('questions_count', questionsCount);
    if (daysSinceRegister != null) setUserProperty('days_since_register', daysSinceRegister);
    if (hasPassport != null) setUserProperty('has_passport', hasPassport);
    if (notificationEnabled != null) setUserProperty('notification_enabled', notificationEnabled);
    if (appVersion != null) setUserProperty('app_version', appVersion);
    if (onboardingCompleted != null) setUserProperty('onboarding_completed', onboardingCompleted);
    if (photoCount != null) setUserProperty('photo_count', photoCount);
  }

  // ─── App Lifecycle ───

  void logAppOpen() {
    _sessionStart = DateTime.now();
    logEvent('app_open');
    _crashlytics.setCustomKey('app_state', 'foreground');
  }

  void logAppForeground() {
    final backgroundDuration = _backgroundStart != null
        ? DateTime.now().difference(_backgroundStart!).inMilliseconds
        : 0;
    _backgroundStart = null;
    logEvent('qulo_app_foreground', params: {
      'background_duration_ms': backgroundDuration,
    });
    _crashlytics.setCustomKey('app_state', 'foreground');
  }

  void logAppBackground() {
    _backgroundStart = DateTime.now();
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inMilliseconds
        : 0;
    logEvent('qulo_app_background', params: {
      'session_duration_ms': sessionDuration,
    });
    _crashlytics.setCustomKey('app_state', 'background');
    _crashlytics.setCustomKey('session_duration_ms', sessionDuration.toString());
  }

  // ─── Non-Fatal Error Tracking ───

  void logNonFatalError(
    Object error,
    StackTrace? stack, {
    String? context,
    Map<String, String>? extras,
  }) {
    if (!_initialized) return;

    if (context != null) {
      _crashlytics.setCustomKey('error_context', context);
    }
    extras?.forEach((key, value) {
      _crashlytics.setCustomKey('err_$key', value);
    });

    _crashlytics.recordError(error, stack, reason: context);

    final params = <String, Object>{};
    if (context != null) params['context'] = context;
    if (extras != null) params.addAll(extras);
    logEvent('app_non_fatal_error', params: params.isEmpty ? null : params);
  }

  // ─── Helpers ───

  static String diamondRange(int balance) {
    if (balance == 0) return '0';
    if (balance <= 100) return '1-100';
    if (balance <= 500) return '100-500';
    return '500+';
  }

  static String ageRange(int age) {
    if (age <= 24) return '18-24';
    if (age <= 30) return '25-30';
    if (age <= 40) return '31-40';
    return '40+';
  }

  static String completionRange(int percent) {
    if (percent <= 25) return '0-25';
    if (percent <= 50) return '25-50';
    if (percent <= 75) return '50-75';
    return '75-100';
  }

  static String matchRange(int count) {
    if (count == 0) return '0';
    if (count <= 5) return '1-5';
    if (count <= 20) return '6-20';
    return '20+';
  }

  static String messageRange(int count) {
    if (count == 0) return '0';
    if (count <= 10) return '1-10';
    if (count <= 50) return '11-50';
    return '50+';
  }

  static String dayRange(DateTime createdAt) {
    final days = DateTime.now().difference(createdAt).inDays;
    if (days <= 1) return '1';
    if (days <= 7) return '2-7';
    if (days <= 30) return '8-30';
    return '30+';
  }

  // ── Deep Link Analytics ──────────────────────────────────────────

  void logDeepLinkReceived(String uri, {required String source}) {
    logEvent(AnalyticsEvents.deepLinkReceived, params: {
      AnalyticsEvents.paramUri: uri,
      AnalyticsEvents.paramSource: source,
    });
  }

  void logDeepLinkNavigated(String targetPath, String navType) {
    logEvent(AnalyticsEvents.deepLinkNavigated, params: {
      AnalyticsEvents.paramTargetPath: targetPath,
      AnalyticsEvents.paramNavType: navType,
    });
  }

  void logDeepLinkDeferred(String targetPath) {
    logEvent(AnalyticsEvents.deepLinkDeferred, params: {
      AnalyticsEvents.paramTargetPath: targetPath,
    });
  }

  void logDeepLinkReplayed(String targetPath) {
    logEvent(AnalyticsEvents.deepLinkReplayed, params: {
      AnalyticsEvents.paramTargetPath: targetPath,
    });
  }

  void logDeepLinkInvalid(String uri, String reason) {
    logEvent(AnalyticsEvents.deepLinkInvalid, params: {
      AnalyticsEvents.paramUri: uri,
      AnalyticsEvents.paramReason: reason,
    });
  }
}
