import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'qulo_default';
  static const _androidChannelName = 'Qulo Bildirimleri';
  static const _androidChannelDescription = 'Eşleşme, mesaj ve diğer bildirimler';

  String? _token;
  String? get token => _token;

  // Stream subscriptions for cleanup
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<void> init() async {
    dev.log('[FCM] init() started', name: 'NotificationManager');

    // Initialize local notifications (Android channel + iOS settings)
    await _initLocalNotifications();

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

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        dev.log('[LocalNotif] Tapped: ${response.payload}', name: 'NotificationManager');
        final actionUrl = response.payload;
        if (actionUrl != null && actionUrl.isNotEmpty) {
          _onLocalNotificationTap?.call(actionUrl);
        }
      },
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      dev.log('[FCM] Android notification channel created', name: 'NotificationManager');
    }

    // Disable iOS native foreground alerts — we handle via local notifications
    // so we can apply suppress logic (e.g., don't show when in active chat)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  /// Show a local notification (used for foreground FCM messages)
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
      payload: message.data['action_url'],
    );
  }

  // Callbacks set by provider layer
  void Function(String token)? _onTokenRefresh;
  void Function(RemoteMessage message)? _onForegroundMessage;
  void Function(RemoteMessage message)? _onMessageOpenedApp;
  void Function(String actionUrl)? _onLocalNotificationTap;
  /// Gelen mesajın banner/local notification olarak gösterilmesini engellemek için.
  /// true dönerse hem banner hem Android local notification suppress edilir.
  bool Function(RemoteMessage message)? shouldSuppressNotification;

  void setCallbacks({
    void Function(String token)? onTokenRefresh,
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
    bool Function(RemoteMessage message)? shouldSuppress,
    void Function(String actionUrl)? onLocalNotificationTap,
  }) {
    _onTokenRefresh = onTokenRefresh;
    _onForegroundMessage = onForegroundMessage;
    _onMessageOpenedApp = onMessageOpenedApp;
    shouldSuppressNotification = shouldSuppress;
    _onLocalNotificationTap = onLocalNotificationTap;

    // Cancel previous listeners to prevent duplicates
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      dev.log('[FCM] Foreground message: ${message.notification?.title}', name: 'NotificationManager');
      AnalyticsManager.instance.logEvent(AnalyticsEvents.notificationReceiveForeground, params: {
        AnalyticsEvents.paramType: message.data['type'] ?? 'unknown',
      });

      // Suppress check — aktif chat'teki mesaj bildirimi ise gösterme
      final suppress = shouldSuppressNotification?.call(message) ?? false;

      // Show local notification for foreground messages (both platforms)
      // Suppress logic handles active chat scenario
      if (!suppress) {
        showLocalNotification(message);
      }

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
    _onLocalNotificationTap = null;
  }
}
