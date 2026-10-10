import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/pref_analytics.dart';

/// Cinsiyet + tercih birlikte yönelim verisi (KVKK m.6; Grindr/Norveç emsali):
/// tercih DEĞERİ hiçbir event'e girmez — yalnız giriş noktası ve rıza cevabı.
void main() {
  late List<Map<String, Object?>> events;
  setUp(() {
    events = [];
    AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  test('kayıtta tercih seçimi: yalnız entry_point', () {
    PrefAnalytics.prefSelected(PrefEntryPoint.signup);
    expect(events, [{'event': AnalyticsEvents.signupGenderPrefSelected, 'entry_point': 'signup'}]);
  });

  test('kurulum kapısında tercih seçimi: yalnız entry_point', () {
    PrefAnalytics.prefSelected(PrefEntryPoint.gate);
    expect(events, [{'event': AnalyticsEvents.setupGenderPrefSelected, 'entry_point': 'gate'}]);
  });

  test('rıza cevabı: entry_point + consent, tercih yok', () {
    PrefAnalytics.consentAnswered(entryPoint: PrefEntryPoint.legacySheet, granted: false);
    expect(events, [{'event': AnalyticsEvents.prefConsentAnswered, 'entry_point': 'legacy_sheet', 'consent': 'declined'}]);
  });
}
