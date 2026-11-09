import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/features/power_demo/data/power_demo_outcome_store.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_outcome.dart';

/// Kayıt/girişten sonra, cihazda saklı onboarding demo sonucunu raporlar (spec §9.2).
///
/// - Firebase kullanıcı özelliği `power_demo`: `completed` | `skipped:N` (N = adım) | `not_seen`
///   (her çağrıda yazılır; idempotent).
/// - `power_demo_outcome` olayı: **bir kez** (`FunnelEvents.logAuthedOnce` + bayrak),
///   Firebase + `flow_events`. `not_seen` de gönderilir — başarı sorgusunun
///   (§9.4) "görmeyen" karşılaştırma grubu buradan okunur.
abstract final class PowerDemoOutcomeReporter {
  static const String _notSeen = 'not_seen';

  static Future<void> reportOnce() async {
    final outcome = await PowerDemoOutcomeStore.read();
    AnalyticsManager.instance.setUserProperty(
      AnalyticsEvents.userPropertyPowerDemo,
      outcome.encode() ?? _notSeen,
    );
    await FunnelEvents.logAuthedOnce(
      AnalyticsEvents.flagPowerDemoOutcomeSent,
      AnalyticsEvents.powerDemoOutcome,
      params: _eventParams(outcome),
    );
  }

  static Map<String, Object> _eventParams(PowerDemoOutcome outcome) =>
      switch (outcome) {
        PowerDemoCompleted() => {AnalyticsEvents.paramOutcome: 'completed'},
        PowerDemoSkipped(:final fromStep) => {
            AnalyticsEvents.paramOutcome: 'skipped',
            AnalyticsEvents.paramFromStep: fromStep,
          },
        PowerDemoNotSeen() => {AnalyticsEvents.paramOutcome: _notSeen},
      };
}
