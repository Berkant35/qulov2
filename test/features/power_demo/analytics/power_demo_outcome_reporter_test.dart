import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/power_demo/analytics/power_demo_outcome_reporter.dart';

/// Kayıt/girişten sonra demo sonucu bir kez raporlanır (spec §9.2, §13.5/15): auth öncesi
/// olaylar `AnalyticsForwarder` token yokken buffer'ı sildiğinden sonuç cihazda saklanır
/// ve ilk Discover girişinde `logAuthedOnce` ile gönderilir.
void main() {
  late List<({String name, Map<String, Object>? params})> events;
  late List<({String name, String? value})> userProperties;

  Future<void> report() => PowerDemoOutcomeReporter.reportOnce();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events = [];
    userProperties = [];
    AnalyticsManager.debugEventSink =
        (name, params) => events.add((name: name, params: params));
    AnalyticsManager.debugUserPropertySink =
        (name, value) => userProperties.add((name: name, value: value));
    // logAuthed AnalyticsForwarder'a da yazar (15 sn'lik zamanlayıcı kurar).
    AnalyticsForwarder.instance.setEnabled(false);
  });

  tearDown(() {
    AnalyticsManager.debugEventSink = null;
    AnalyticsManager.debugUserPropertySink = null;
    AnalyticsForwarder.instance.setEnabled(true);
  });

  test('bir kez gönderir, ikinci çağrı göndermez', () async {
    SharedPreferences.setMockInitialValues({'power_demo_outcome_v1': 'completed'});

    await report();
    await report();

    expect(events, hasLength(1));
    expect(events.single.name, AnalyticsEvents.powerDemoOutcome);
    expect(events.single.name, 'power_demo_outcome');
  });

  test('completed: outcome=completed, from_step yok', () async {
    SharedPreferences.setMockInitialValues({'power_demo_outcome_v1': 'completed'});

    await report();

    expect(events.single.params, {'outcome': 'completed'});
  });

  test('skipped: outcome=skipped + from_step', () async {
    SharedPreferences.setMockInitialValues({'power_demo_outcome_v1': 'skipped:3'});

    await report();

    expect(events.single.params, {'outcome': 'skipped', 'from_step': 3});
  });

  test('demo hiç görülmediyse not_seen yine de bir kez raporlanır (karşılaştırma grubu)', () async {
    await report();
    await report();

    expect(events, hasLength(1));
    expect(events.single.params, {'outcome': 'not_seen'});
  });

  test('kullanıcı özelliği power_demo: completed / skipped:<adım> / not_seen', () async {
    SharedPreferences.setMockInitialValues({'power_demo_outcome_v1': 'skipped:3'});
    await report();
    expect(userProperties, [(name: 'power_demo', value: 'skipped:3')]);

    userProperties.clear();
    SharedPreferences.setMockInitialValues({'power_demo_outcome_v1': 'completed'});
    await report();
    expect(userProperties, [(name: 'power_demo', value: 'completed')]);

    userProperties.clear();
    SharedPreferences.setMockInitialValues({});
    await report();
    expect(userProperties, [(name: 'power_demo', value: 'not_seen')]);
  });

  test('bayrak anahtarı kalıcı: gönderim sonrası SharedPreferences\'ta işaretli', () async {
    await report();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AnalyticsEvents.flagPowerDemoOutcomeSent), isTrue);
  });

  test('sabitler: olay, kullanıcı özelliği ve bayrak adları', () {
    expect(AnalyticsEvents.powerDemoOutcome, 'power_demo_outcome');
    expect(AnalyticsEvents.userPropertyPowerDemo, 'power_demo');
    expect(AnalyticsEvents.paramOutcome, 'outcome');
    expect(AnalyticsEvents.flagPowerDemoOutcomeSent, isNotEmpty);
  });
}
