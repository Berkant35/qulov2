import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/observers/route_change_notifier.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';

typedef _Logged = ({String name, Map<String, Object>? params});

/// Spec §9.3 + §13.5/16: tanıtım turları `coach_tour_shown` / `coach_tour_completed` /
/// `coach_tour_skipped` üretir. completed = son adımda "ileri", skipped = "tümünü atla"
/// (kapat ikonu). `forceClose()` / `_cleanup()` olay ÜRETMEZ — her sohbet ekranı
/// kapanışında çağrılıyor. `step_index` 1 tabanlı (analitikte "adım 3").
void main() {
  final next = AppLocalizations(const Locale('en')).get('coach_cta_next');
  final start = AppLocalizations(const Locale('en')).get('coach_cta_start');

  const steps = [
    CoachMarkStep(
        titleKey: 'coach_discover_intro_title',
        bodyKey: 'coach_discover_intro_body',
        ctaKey: 'coach_cta_next'),
    CoachMarkStep(
        titleKey: 'coach_discover_solve_title',
        bodyKey: 'coach_discover_solve_body',
        ctaKey: 'coach_cta_next'),
    CoachMarkStep(
        titleKey: 'coach_discover_solve_title',
        bodyKey: 'coach_discover_solve_body',
        ctaKey: 'coach_cta_start'),
  ];

  late List<_Logged> events;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events = [];
    AnalyticsManager.debugEventSink =
        (name, params) => events.add((name: name, params: params));
  });

  tearDown(() {
    CoachMarkService.instance.forceClose();
    AnalyticsManager.debugEventSink = null;
  });

  Widget app() => MaterialApp(
        navigatorObservers: [RouteChangeObserver()],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const Scaffold(body: Text('home')),
      );

  Future<BuildContext> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    return tester.element(find.text('home'));
  }

  List<String> names() => events.map((e) => e.name).toList();

  testWidgets('tur açılınca coach_tour_shown {tour_id} atılır', (tester) async {
    final context = await pumpHome(tester);

    unawaited(CoachMarkService.instance.maybeStartTour(context, tourId: 't_shown', steps: steps));
    await tester.pumpAndSettle();

    expect(events, hasLength(1));
    expect(events.single.name, AnalyticsEvents.coachTourShown);
    expect(events.single.params, {AnalyticsEvents.paramTourId: 't_shown'});

    // Açık tur gövdede kapatılır: tearDown'daki forceClose ağaç sökülünce geç kalır
    // ve kuyruğu serbest bırakmaz (sonraki test turu açamaz).
    CoachMarkService.instance.forceClose();
    await tester.pumpAndSettle();
  });

  testWidgets('son adımda next → completed {tour_id, step_index = adım sayısı}; ara adımlar olay atmaz',
      (tester) async {
    final context = await pumpHome(tester);
    unawaited(CoachMarkService.instance.maybeStartTour(context, tourId: 't_done', steps: steps));
    await tester.pumpAndSettle();

    await tester.tap(find.text(next));
    await tester.pumpAndSettle();
    await tester.tap(find.text(next));
    await tester.pumpAndSettle();
    expect(names(), [AnalyticsEvents.coachTourShown], reason: 'ara adım olay üretmez');

    await tester.tap(find.text(start));
    await tester.pumpAndSettle();

    expect(names(), [AnalyticsEvents.coachTourShown, AnalyticsEvents.coachTourCompleted]);
    expect(events.last.params, {
      AnalyticsEvents.paramTourId: 't_done',
      AnalyticsEvents.paramStepIndex: 3,
    });
  });

  testWidgets('skipAll → skipped {tour_id, step_index = o anki adım, 1 tabanlı}', (tester) async {
    final context = await pumpHome(tester);
    unawaited(CoachMarkService.instance.maybeStartTour(context, tourId: 't_skip', steps: steps));
    await tester.pumpAndSettle();

    await tester.tap(find.text(next)); // 1. adımdan 2. adıma
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close)); // 2. adımda "tümünü atla"
    await tester.pumpAndSettle();

    expect(names(), [AnalyticsEvents.coachTourShown, AnalyticsEvents.coachTourSkipped],
        reason: 'atlanan tur completed sayılmaz');
    expect(events.last.params, {
      AnalyticsEvents.paramTourId: 't_skip',
      AnalyticsEvents.paramStepIndex: 2,
    });
    expect(await CoachMarkService.instance.isSeen('t_skip'), isTrue,
        reason: 'atlama da turu görüldü sayar (davranış değişmez)');
  });

  testWidgets('ilk adımda atlama step_index 1 taşır', (tester) async {
    final context = await pumpHome(tester);
    unawaited(CoachMarkService.instance.maybeStartTour(context, tourId: 't_skip1', steps: steps));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(events.last.name, AnalyticsEvents.coachTourSkipped);
    expect(events.last.params![AnalyticsEvents.paramStepIndex], 1);
  });

  testWidgets('forceClose (tur açıkken) → completed/skipped yok, görüldü sayılmaz', (tester) async {
    final context = await pumpHome(tester);
    unawaited(CoachMarkService.instance.maybeStartTour(context, tourId: 't_force', steps: steps));
    await tester.pumpAndSettle();
    events.clear(); // yalnız forceClose'un ürettiği olaylar ölçülür (shown önceden atıldı)

    CoachMarkService.instance.forceClose();
    await tester.pumpAndSettle();

    expect(events, isEmpty, reason: 'ekran kapanışı kullanıcı kararı değil, olay üretmez');
    expect(await CoachMarkService.instance.isSeen('t_force'), isFalse);
  });

  testWidgets('forceClose (kuyrukta beklerken) → hiç olay yok', (tester) async {
    final context = await pumpHome(tester);
    final blocker = Completer<void>();
    OverlayQueueService.instance.enqueue(OverlayRequest(
      id: 'blocker',
      priority: OverlayPriority.campaign,
      show: () => blocker.future,
    ));

    unawaited(CoachMarkService.instance.maybeStartTour(context, tourId: 't_queued', steps: steps));
    await tester.pump();

    CoachMarkService.instance.forceClose();
    await tester.pump();

    expect(events, isEmpty, reason: 'tur hiç gösterilmedi → shown da yok');

    // Engelleyici gövdede serbest bırakılır: kuyruk geri çağrıları FakeAsync
    // bölgesinde koşar, test bitince ilerlemez → sonraki test kuyruğu dolu bulurdu
    // ("görülmüşse shown atılmaz" boşuna geçerdi).
    blocker.complete();
    await tester.pump();
    expect(OverlayQueueService.instance.isShowing, isFalse);
  });

  testWidgets('tur görülmüşse shown atılmaz', (tester) async {
    final context = await pumpHome(tester);
    await CoachMarkService.instance.markSeen('t_seen');

    unawaited(CoachMarkService.instance.maybeStartTour(context, tourId: 't_seen', steps: steps));
    await tester.pumpAndSettle();

    expect(events, isEmpty);
    expect(find.text(next), findsNothing);
  });
}
