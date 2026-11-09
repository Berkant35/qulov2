import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';

/// Olay gönderici imzası ([FunnelEvents.logAuthed] ile aynı).
typedef AdAnalyticsSink = void Function(String name, {Map<String, Object>? params});

/// Discover native reklam olayları. Hepsi `placement=discover` taşır
/// (`entry_point` DEĞİL — o güç demosuna ait). Reklam AUTH SONRASI gösterilir →
/// Firebase + sunucu `flow_events`.
class AdAnalytics {
  AdAnalytics({AdAnalyticsSink? sink}) : _sink = sink ?? FunnelEvents.logAuthed;

  final AdAnalyticsSink _sink;

  void slotShown() => _log(AnalyticsEvents.adSlotShown);
  void loaded() => _log(AnalyticsEvents.adLoaded);
  void failed(int errorCode) =>
      _log(AnalyticsEvents.adFailed, {AnalyticsEvents.paramErrorCode: errorCode});
  void clicked() => _log(AnalyticsEvents.adClicked);
  void impression() => _log(AnalyticsEvents.adImpression);

  void _log(String name, [Map<String, Object> extra = const {}]) => _sink(
        name,
        params: {
          AnalyticsEvents.paramPlacement: AnalyticsEvents.placementDiscover,
          ...extra,
        },
      );
}
