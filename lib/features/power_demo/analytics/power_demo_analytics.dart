import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';

/// Olay gönderici imzası ([FunnelEvents.logPreAuth] / [FunnelEvents.logAuthed] ile aynı).
/// `dart:async`'in `EventSink`'iyle karışmasın diye bu ad.
typedef AnalyticsSink = void Function(String name, {Map<String, Object>? params});

/// Güç demosu olayları — "kim atladı / bitirdi / nerede bıraktı" ölçümü (spec §9.1).
///
/// Taşıma girişe göre seçilir: onboarding demosu AUTH ÖNCESİ oynanır → [preAuth]
/// (yalnız Firebase; `AnalyticsForwarder` token yokken buffer'ı siler). `market` /
/// `quiz_intro` girişleri auth SONRASI → [authed] (Firebase + sunucu `flow_events`).
///
/// Her olay `entry_point` taşır; `source` ASLA (GA4'te `quiz_power_used`'ın harcama
/// kaynağını taşıyor, çakışma mor analizini bozar).
///
/// Adım numaraları **1 tabanlıdır** ("adım 3"): çağıran `stepIndex + 1` verir, burada
/// dönüştürme yapılmaz.
class PowerDemoAnalytics {
  PowerDemoAnalytics(
    this.entryPoint, {
    AnalyticsSink? preAuth,
    AnalyticsSink? authed,
  }) : _sink = entryPoint == PowerDemoEntryPoint.onboarding
            ? (preAuth ?? FunnelEvents.logPreAuth)
            : (authed ?? FunnelEvents.logAuthed);

  final PowerDemoEntryPoint entryPoint;
  final AnalyticsSink _sink;

  void start() => _log(AnalyticsEvents.powerDemoStart);

  void stepView(int step, DemoPower? power) => _log(
        AnalyticsEvents.powerDemoStepView,
        {AnalyticsEvents.paramStepIndex: step, ..._power(power)},
      );

  void powerUsed(int step, DemoPower power, int msToTap) => _log(
        AnalyticsEvents.powerDemoPowerUsed,
        {
          AnalyticsEvents.paramStepIndex: step,
          ..._power(power),
          AnalyticsEvents.paramMsToTap: msToTap,
        },
      );

  void answer(int step, {required bool correct}) => _log(
        AnalyticsEvents.powerDemoAnswer,
        {
          AnalyticsEvents.paramStepIndex: step,
          AnalyticsEvents.paramCorrect: correct,
        },
      );

  void rescueUsed(int step) => _log(
        AnalyticsEvents.powerDemoRescueUsed,
        {AnalyticsEvents.paramStepIndex: step},
      );

  /// "Hepsini atlayan" bu olaydır: nerede ([fromStep]) ve ne kadar sonra bıraktı.
  void skip({
    required int fromStep,
    DemoPower? power,
    required int durationMs,
  }) =>
      _log(AnalyticsEvents.powerDemoSkip, {
        AnalyticsEvents.paramFromStep: fromStep,
        ..._power(power),
        AnalyticsEvents.paramDurationMs: durationMs,
      });

  void complete({required int durationMs, required int wrongAnswers}) => _log(
        AnalyticsEvents.powerDemoComplete,
        {
          AnalyticsEvents.paramDurationMs: durationMs,
          AnalyticsEvents.paramWrongAnswers: wrongAnswers,
        },
      );

  /// Güç adı sunucu `apiName`'iyle (quiz `quiz_power_used` ile aynı biçim); güç yoksa anahtar yok.
  Map<String, Object> _power(DemoPower? power) =>
      power == null ? const {} : {AnalyticsEvents.paramPower: power.apiName};

  void _log(String name, [Map<String, Object> params = const {}]) => _sink(
        name,
        params: {
          AnalyticsEvents.paramEntryPoint: entryPoint.analyticsValue,
          ...params,
        },
      );
}
