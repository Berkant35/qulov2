import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';

/// Hibrit funnel logger.
///
/// - [logPreAuth]: auth ONCESI event — yalnizca Firebase (client-side, JWT
///   gerekmez). Carousel, landing, register adimlari icin.
/// - [logAuthed]: auth SONRASI event — Firebase + server `flow_events`
///   (POST /analytics/track, JWT'li). Admin panelde SQL sorgulanabilir.
/// - [logAuthedOnce]: tek-seferlik logAuthed (ilk discover / ilk quiz gibi).
///
/// Firebase = tam funnel gorunumu; server = auth-sonrasi detay.
abstract final class FunnelEvents {
  static void logPreAuth(String name, {Map<String, Object>? params}) {
    AnalyticsManager.instance.logEvent(name, params: params);
  }

  static void logAuthed(String name, {Map<String, Object>? params}) {
    AnalyticsManager.instance.logEvent(name, params: params);
    AnalyticsForwarder.instance.track(
      name,
      category: 'funnel',
      metadata: params,
    );
  }

  static Future<void> logAuthedOnce(
    String flagKey,
    String name, {
    Map<String, Object>? params,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(flagKey) ?? false) return;
    await prefs.setBool(flagKey, true);
    logAuthed(name, params: params);
  }
}
