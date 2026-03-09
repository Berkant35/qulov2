import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  dev.log('[FCM] Background message received: ${message.messageId}', name: 'NotificationManager');
}

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _token;
  String? get token => _token;

  // Stream subscriptions for cleanup
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<void> init() async {
    dev.log('[FCM] init() started', name: 'NotificationManager');

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    dev.log('[FCM] Permission status: ${settings.authorizationStatus}', name: 'NotificationManager');

    AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationPermissionAsk);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationPermissionGrant);
      AnalyticsManager.instance.setUserProperty('notification_enabled', 'true');
    } else {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationPermissionDeny);
      AnalyticsManager.instance.setUserProperty('notification_enabled', 'false');
    }

    // iOS: wait for APNS token before requesting FCM token
    if (Platform.isIOS) {
      dev.log('[FCM] iOS detected — waiting for APNS token...', name: 'NotificationManager');
      String? apnsToken;
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await _messaging.getAPNSToken();
        dev.log('[FCM] APNS retry ${i + 1}: ${apnsToken != null ? "OK" : "NULL"}', name: 'NotificationManager');
        if (apnsToken != null) break;
      }

      if (apnsToken == null) {
        dev.log('[FCM] APNS token not available — will rely on onTokenRefresh', name: 'NotificationManager');
      }
    }

    // Get FCM token
    try {
      _token = await _messaging.getToken();
      dev.log('[FCM] Token: ${_token != null ? '${_token!.substring(0, 20)}...' : 'NULL'}', name: 'NotificationManager');
    } catch (e) {
      dev.log('[FCM] Token fetch failed: $e', name: 'NotificationManager');
      _token = null;
    }

    // Listen for token refresh (cancel previous if re-inited)
    _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      dev.log('[FCM] Token refreshed', name: 'NotificationManager');
      _token = newToken;
      _onTokenRefresh?.call(newToken);
    });

    dev.log('[FCM] init() completed', name: 'NotificationManager');
  }

  // Callbacks set by provider layer
  void Function(String token)? _onTokenRefresh;
  void Function(RemoteMessage message)? _onForegroundMessage;
  void Function(RemoteMessage message)? _onMessageOpenedApp;

  void setCallbacks({
    void Function(String token)? onTokenRefresh,
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
  }) {
    _onTokenRefresh = onTokenRefresh;
    _onForegroundMessage = onForegroundMessage;
    _onMessageOpenedApp = onMessageOpenedApp;

    // Cancel previous listeners to prevent duplicates
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      dev.log('[FCM] Foreground message: ${message.notification?.title}', name: 'NotificationManager');
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationReceiveForeground, params: {
        AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
      });
      _onForegroundMessage?.call(message);
    });

    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      dev.log('[FCM] Message opened app: ${message.notification?.title}', name: 'NotificationManager');
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationTap, params: {
        AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
        AnalyticsEvents.paramActionUrl: message.data['action_url'] ?? '',
      });
      _onMessageOpenedApp?.call(message);
    });

    dev.log('[FCM] Callbacks set', name: 'NotificationManager');
  }

  /// Get the notification that launched the app from terminated state (one-time)
  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _onTokenRefresh = null;
    _onForegroundMessage = null;
    _onMessageOpenedApp = null;
  }
}
