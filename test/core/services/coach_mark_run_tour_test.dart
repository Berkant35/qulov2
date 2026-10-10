import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/observers/route_change_notifier.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';

/// `runTour`: bir işlemi tur kapanana kadar bekletir (quiz oturumu güç turu
/// bitince açılır — sunucu süresi tur sırasında işlemesin). Bekleyen akış
/// hiçbir yolda takılı kalmamalı.
void main() {
  final cta = AppLocalizations(const Locale('en')).get('coach_cta_got_it');

  const steps = [
    CoachMarkStep(
      titleKey: 'coach_quiz_powers_title',
      bodyKey: 'coach_quiz_powers_body',
      ctaKey: 'coach_cta_got_it',
    ),
  ];

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => CoachMarkService.instance.forceClose());

  Widget app() => MaterialApp(
        navigatorObservers: [RouteChangeObserver()],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const Scaffold(body: Text('home')),
      );

  testWidgets('tur kapanana kadar bekler; CTA ile kapanınca devam eder ve görüldü sayılır',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.text('home'));

    var done = false;
    unawaited(CoachMarkService.instance
        .runTour(context, tourId: 't_wait', steps: steps)
        .then((_) => done = true));
    await tester.pumpAndSettle();
    expect(find.text(cta), findsOneWidget);
    expect(done, isFalse, reason: 'tur açıkken akış başlamamalı');

    await tester.tap(find.text(cta));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(await CoachMarkService.instance.isSeen('t_wait'), isTrue);
  });

  testWidgets('görülmüş tur beklemeden döner', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.text('home'));
    await CoachMarkService.instance.markSeen('t_seen');

    var done = false;
    unawaited(CoachMarkService.instance
        .runTour(context, tourId: 't_seen', steps: steps)
        .then((_) => done = true));
    await tester.pump();

    expect(done, isTrue);
    expect(find.text(cta), findsNothing);
  });

  testWidgets('tur açıkken ekran kapanırsa (forceClose) bekleyen akış takılmaz', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.text('home'));

    var done = false;
    unawaited(CoachMarkService.instance
        .runTour(context, tourId: 't_close', steps: steps)
        .then((_) => done = true));
    await tester.pumpAndSettle();

    CoachMarkService.instance.forceClose();
    await tester.pump();

    expect(done, isTrue);
    expect(await CoachMarkService.instance.isSeen('t_close'), isFalse);
  });

  testWidgets('kuyrukta beklerken iptal edilirse (forceClose) bekleyen akış takılmaz',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.text('home'));
    final blocker = Completer<void>();
    OverlayQueueService.instance.enqueue(OverlayRequest(
      id: 'blocker',
      priority: OverlayPriority.campaign,
      show: () => blocker.future,
    ));
    addTearDown(blocker.complete);

    var done = false;
    unawaited(CoachMarkService.instance
        .runTour(context, tourId: 't_queued', steps: steps)
        .then((_) => done = true));
    await tester.pump();
    expect(done, isFalse);

    CoachMarkService.instance.forceClose();
    await tester.pump();

    expect(done, isTrue);
  });
}
