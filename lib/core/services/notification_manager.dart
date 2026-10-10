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

  /// Yerel bildirim kanalı, arka plan işleyicisi ve — izin ZATEN verilmişse —
  /// FCM token'ı. Sistem izni burada SORULMAZ: login sonrası soğuk istem
  /// (ATT + konum + push art arda) kaldırıldı; izin değerli anda
  /// [requestPermission] ile, açıklama ekranından sonra istenir. İzinli
  /// kullanıcıda token her açılışta tazelenir.
  Future<void> init() async {
    dev.log('[FCM] init() started', name: 'NotificationManager');

    // Initialize local notifications (Android channel + iOS settings)
    await _initLocalNotifications();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Listen for token refresh (cancel previous if re-inited)
    _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      dev.log('[FCM] Token refreshed', name: 'NotificationManager');
      _token = newToken;
      _onTokenRefresh?.call(newToken);
    });

    final granted = await isPermissionGranted();
    dev.log('[FCM] Permission granted: $granted', name: 'NotificationManager');
    AnalyticsManager.instance.setUserProperty('notification_enabled', '$granted');
    if (granted) await _fetchToken();

    dev.log('[FCM] init() completed', name: 'NotificationManager');
  }

  Future<bool> isPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return _isGranted(settings.authorizationStatus);
  }

  /// Açıklama ekranı gösterilmeye değer mi? İzin zaten varsa hayır. iOS bir kez
  /// reddedilen izni bir daha sormaz (yalnız Ayarlar) → yalnız "hiç sorulmadı"
  /// iken evet. Android 13+ "reddedildi" ile "hiç sorulmadı"yı ayırt ettirmez;
  /// sistem diyaloğu gösterip göstermeyeceğine kendisi karar verir.
  Future<bool> canRequestPermission() async {
    final status = (await _messaging.getNotificationSettings()).authorizationStatus;
    if (_isGranted(status)) return false;
    return Platform.isIOS ? status == AuthorizationStatus.notDetermined : true;
  }

  /// Sistem izin istemini açar (iOS + Android 13+ POST_NOTIFICATIONS). İzin
  /// verilirse token alınır; [token] üzerinden okunur.
  Future<bool> requestPermission({required String trigger}) async {
    final params = {AnalyticsEvents.paramTrigger: trigger};
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    dev.log('[FCM] Permission status: ${settings.authorizationStatus}', name: 'NotificationManager');

    final analytics = AnalyticsManager.instance;
    analytics.logEvent(AnalyticsEvents.notificationPermissionAsk, params: params);
    final granted = _isGranted(settings.authorizationStatus);
    analytics.logEvent(
      granted
          ? AnalyticsEvents.notificationPermissionGrant
          : AnalyticsEvents.notificationPermissionDeny,
      params: params,
    );
    analytics.setUserProperty('notification_enabled', '$granted');
    if (granted) await _fetchToken();
    return granted;
  }

  static bool _isGranted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> _fetchToken() async {
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

    try {
      _token = await _messaging.getToken();
      dev.log('[FCM] Token: ${_token != null ? 'OK' : 'NULL'}', name: 'NotificationManager');
    } catch (e) {
      dev.log('[FCM] Token fetch failed: $e', name: 'NotificationManager');
      _token = null;
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Varsayılan (true) iOS'ta initialize anında sistem izin istemini açar —
    // izin yalnız [requestPermission] ile, açıklama ekranından sonra istenir.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
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
