import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/att_manager.dart';

/// Meta (Facebook) App Events manager — Meta reklam kampanyalarının
/// install attribution'ı için standart app event'lerini gönderir.
///
/// Purchase eventi BİLİNÇLİ olarak yok: RevenueCat'in Meta Ads entegrasyonu
/// satın almaları server-side gönderiyor; SDK'dan da gönderilirse çift sayım olur.
class MetaEventsManager {
  MetaEventsManager._();
  static final MetaEventsManager instance = MetaEventsManager._();

  final FacebookAppEvents _events = FacebookAppEvents();
  bool _initialized = false;

  /// fb_mobile_activate_app otomatik atılır (AutoLogAppEventsEnabled).
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _events.setAutoLogAppEventsEnabled(true);
      _initialized = true;
      dev.log('[Meta] Initialized', name: 'MetaEventsManager');
    } catch (e, st) {
      AnalyticsManager.instance
          .logNonFatalError(e, st, context: 'MetaEventsManager.init');
    }
  }

  /// ATT prompt'undan SONRA çağrılmalı — kullanıcının tracking kararını
  /// Meta SDK'ya iletir (iOS Advertiser Tracking Enabled bayrağı).
  /// Reddedilirse event'ler anonim/aggregated (SKAdNetwork) akmaya devam eder.
  Future<void> syncAdvertiserTracking() async {
    if (!_initialized || !Platform.isIOS) return;
    try {
      final authorized = await AttManager.instance.isAuthorized();
      await _events.setAdvertiserTracking(enabled: authorized);
      dev.log('[Meta] Advertiser tracking: $authorized',
          name: 'MetaEventsManager');
    } catch (e, st) {
      AnalyticsManager.instance.logNonFatalError(e, st,
          context: 'MetaEventsManager.syncAdvertiserTracking');
    }
  }

  /// RevenueCat → Meta Ads eşleşmesi için FB anonymous ID
  /// (`$fbAnonId` attribute'u — IDFA reddedilse bile purchase attribution sağlar).
  Future<String?> getAnonymousId() async {
    if (!_initialized) return null;
    try {
      return await _events.getAnonymousId();
    } catch (e, st) {
      AnalyticsManager.instance
          .logNonFatalError(e, st, context: 'MetaEventsManager.getAnonymousId');
      return null;
    }
  }

  /// fb_mobile_complete_registration — install kampanyalarının
  /// optimize edildiği standart kayıt eventi.
  Future<void> logCompleteRegistration({String? method}) async {
    if (!_initialized) return;
    try {
      await _events.logCompletedRegistration(registrationMethod: method);
      dev.log('[Meta] complete_registration (method: $method)',
          name: 'MetaEventsManager');
    } catch (e, st) {
      AnalyticsManager.instance.logNonFatalError(e, st,
          context: 'MetaEventsManager.logCompleteRegistration');
    }
  }
}
