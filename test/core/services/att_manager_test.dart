import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/att_manager.dart';

/// ATT istemi (2026-09-23): `runApp`'ten once await edilince iOS diyalogu hic
/// gorunmuyordu (uygulama aktif degil) → IDFA yok → reklam yuklemeleri GA4'te
/// (direct). iOS dali cihazda dogrulanir (host macOS); burada platform
/// kisa devresi ve olay/kanit sozlesmesi.
void main() {
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('non-iOS: uygulama aktif olmasa da beklemeden authorized doner', (tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage(AppLifecycleState.inactive.toString()),
      (_) {},
    );
    final logged = <String>[];
    AnalyticsManager.debugEventSink = (name, _) => logged.add(name);

    final status = await AttManager.instance.requestWhenActive();

    expect(status, TrackingStatus.authorized);
    expect(logged, isEmpty, reason: 'istem gosterilmedi, att_prompt_result atilmaz');
  });
}
