import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/power_demo/analytics/power_demo_analytics.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';

typedef _Logged = ({String name, Map<String, Object>? params});

/// Güç demosu olay sözleşmesi (spec §9.1): auth öncesi (onboarding) olaylar yalnız
/// Firebase'e (`preAuth`), auth sonrası (market / quiz_intro) Firebase + `flow_events`'e
/// (`authed`) gider. Parametre adı `entry_point` — `source` değil (§13.5/13).
void main() {
  late List<_Logged> preAuth;
  late List<_Logged> authed;

  PowerDemoAnalytics build(PowerDemoEntryPoint entry) => PowerDemoAnalytics(
        entry,
        preAuth: (name, {params}) => preAuth.add((name: name, params: params)),
        authed: (name, {params}) => authed.add((name: name, params: params)),
      );

  /// Yedi metodun hepsini bir kez çağırır (her olay tipi bir kez üretilir).
  void fireAll(PowerDemoAnalytics a) {
    a.start();
    a.stepView(2, DemoPower.oracle);
    a.powerUsed(2, DemoPower.oracle, 850);
    a.answer(2, correct: true);
    a.rescueUsed(5);
    a.skip(fromStep: 3, power: DemoPower.hint, durationMs: 4200);
    a.complete(durationMs: 61000, wrongAnswers: 1);
  }

  setUp(() {
    preAuth = [];
    authed = [];
  });

  group('taşıma (hangi sink)', () {
    test("onboarding olayları yalnız preAuth'a gider", () {
      fireAll(build(PowerDemoEntryPoint.onboarding));

      expect(authed, isEmpty, reason: 'auth öncesi olay flow_events\'e gitmez (token yok)');
      expect(preAuth.map((e) => e.name), [
        AnalyticsEvents.powerDemoStart,
        AnalyticsEvents.powerDemoStepView,
        AnalyticsEvents.powerDemoPowerUsed,
        AnalyticsEvents.powerDemoAnswer,
        AnalyticsEvents.powerDemoRescueUsed,
        AnalyticsEvents.powerDemoSkip,
        AnalyticsEvents.powerDemoComplete,
      ]);
    });

    test("market olayları yalnız authed'a gider", () {
      fireAll(build(PowerDemoEntryPoint.market));

      expect(preAuth, isEmpty);
      expect(authed, hasLength(7));
    });

    test("quiz_intro olayları yalnız authed'a gider", () {
      fireAll(build(PowerDemoEntryPoint.quizIntro));

      expect(preAuth, isEmpty);
      expect(authed, hasLength(7));
    });
  });

  group('parametreler', () {
    test('her olay entry_point taşır, source taşımaz', () {
      for (final entry in PowerDemoEntryPoint.values) {
        preAuth.clear();
        authed.clear();
        fireAll(build(entry));

        final all = [...preAuth, ...authed];
        expect(all, hasLength(7), reason: '${entry.name}: 7 olay');
        for (final event in all) {
          expect(
            event.params?[AnalyticsEvents.paramEntryPoint],
            entry.analyticsValue,
            reason: '${event.name} entry_point taşımalı',
          );
          expect(
            event.params?.containsKey(AnalyticsEvents.paramSource),
            isFalse,
            reason: '${event.name}: source quiz_power_used harcama kaynağını taşır, çakışır',
          );
        }
      }
    });

    test('parametre adları sabit: entry_point / ms_to_tap / from_step', () {
      expect(AnalyticsEvents.paramEntryPoint, 'entry_point');
      expect(AnalyticsEvents.paramMsToTap, 'ms_to_tap');
      expect(AnalyticsEvents.paramFromStep, 'from_step');
      expect(AnalyticsEvents.paramTourId, 'tour_id');
    });

    test('skip: from_step + duration_ms (+ power)', () {
      build(PowerDemoEntryPoint.market).skip(
        fromStep: 3,
        power: DemoPower.hint,
        durationMs: 4200,
      );

      expect(authed.single.name, 'power_demo_skip');
      expect(authed.single.params, {
        'entry_point': 'market',
        'from_step': 3,
        'power': 'HINT',
        'duration_ms': 4200,
      });
    });

    test('skip: güç henüz yokken power anahtarı hiç yazılmaz', () {
      build(PowerDemoEntryPoint.market).skip(fromStep: 1, durationMs: 900);

      expect(authed.single.params, {
        'entry_point': 'market',
        'from_step': 1,
        'duration_ms': 900,
      });
    });

    test('step_view: step_index 1 tabanlı olduğu gibi geçer; power yoksa yazılmaz', () {
      final a = build(PowerDemoEntryPoint.quizIntro);
      a.stepView(1, null);
      a.stepView(4, DemoPower.skipAll);

      expect(authed[0].params, {'entry_point': 'quiz_intro', 'step_index': 1});
      expect(authed[1].params, {
        'entry_point': 'quiz_intro',
        'step_index': 4,
        'power': 'SKIP_ALL',
      });
    });

    test('power_used: güç adı sunucu apiName, ms_to_tap', () {
      build(PowerDemoEntryPoint.market).powerUsed(5, DemoPower.timeExtend, 1230);

      expect(authed.single.name, 'power_demo_power_used');
      expect(authed.single.params, {
        'entry_point': 'market',
        'step_index': 5,
        'power': 'TIME_EXTEND',
        'ms_to_tap': 1230,
      });
    });

    test('answer: correct bayrağı; rescue_used: yalnız step_index', () {
      final a = build(PowerDemoEntryPoint.market);
      a.answer(3, correct: false);
      a.rescueUsed(6);

      expect(authed[0].name, 'power_demo_answer');
      expect(authed[0].params, {
        'entry_point': 'market',
        'step_index': 3,
        'correct': false,
      });
      expect(authed[1].name, 'power_demo_rescue_used');
      expect(authed[1].params, {'entry_point': 'market', 'step_index': 6});
    });

    test('complete: duration_ms + wrong_answers; start: yalnız entry_point', () {
      final a = build(PowerDemoEntryPoint.onboarding);
      a.start();
      a.complete(durationMs: 61000, wrongAnswers: 2);

      expect(preAuth[0].params, {'entry_point': 'onboarding'});
      expect(preAuth[1].name, 'power_demo_complete');
      expect(preAuth[1].params, {
        'entry_point': 'onboarding',
        'duration_ms': 61000,
        'wrong_answers': 2,
      });
    });
  });

  group('varsayılan sink bağlantısı (FunnelEvents)', () {
    late List<String> firebase;

    setUp(() {
      firebase = [];
      AnalyticsManager.debugEventSink = (name, _) => firebase.add(name);
      // authed varsayılanı AnalyticsForwarder'a da yazar (15 sn'lik zamanlayıcı kurar).
      AnalyticsForwarder.instance.setEnabled(false);
    });

    tearDown(() {
      AnalyticsManager.debugEventSink = null;
      AnalyticsForwarder.instance.setEnabled(true);
    });

    test('sink verilmezse onboarding da market de Firebase\'e düşer', () {
      PowerDemoAnalytics(PowerDemoEntryPoint.onboarding).start();
      PowerDemoAnalytics(PowerDemoEntryPoint.market).start();

      expect(firebase, [AnalyticsEvents.powerDemoStart, AnalyticsEvents.powerDemoStart]);
    });
  });
}
