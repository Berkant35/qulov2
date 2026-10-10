import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/identity_analytics.dart';

/// Etiket DEĞERİ ve grup doluluğu hiçbir event'e girmez (KVKK m.6; GA4 Google Ads'e bağlı,
/// yönelim varlığı bayrağı hassas kategori vekili olurdu) — yalnız entry_point.
void main() {
  late List<Map<String, Object?>> events;
  setUp(() {
    events = [];
    AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  test('saved: yalnız entry_point — değer ve grup bayrağı yok', () {
    IdentityAnalytics.saved(entryPoint: IdentityEntryPoint.banner);
    expect(events, [
      {'event': AnalyticsEvents.identityLabelsSaved, 'entry_point': 'profile_banner'},
    ]);
  });

  test('cleared: yalnız entry_point', () {
    IdentityAnalytics.cleared(entryPoint: IdentityEntryPoint.editProfile);
    expect(events, [
      {'event': AnalyticsEvents.identityLabelsCleared, 'entry_point': 'edit_profile'},
    ]);
  });
}
