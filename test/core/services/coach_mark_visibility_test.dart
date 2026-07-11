import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/observers/route_change_notifier.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';

/// Regression tests for the first-login bug where coach-mark tooltips were
/// drawn ON TOP of bottom sheets / pushed routes (root overlay is above all
/// routes), hiding what they pointed at and blocking the sheet's buttons.
/// The tour must only be on screen while its trigger screen is the visible
/// top route.
void main() {
  final title =
      AppLocalizations(const Locale('en')).get('coach_discover_intro_title');
  final cta = AppLocalizations(const Locale('en')).get('coach_cta_start');

  const steps = [
    CoachMarkStep(
      titleKey: 'coach_discover_intro_title',
      bodyKey: 'coach_discover_intro_body',
      ctaKey: 'coach_cta_start',
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

  testWidgets('tour hides under a modal sheet and re-appears when it closes',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.text('home'));

    await CoachMarkService.instance
        .maybeStartTour(context, tourId: 't_sheet', steps: steps);
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);

    // A bottom sheet opens over the screen → tooltip must leave the screen.
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
    expect(find.text(title), findsNothing);
    expect(CoachMarkService.instance.isTourActive, isTrue);

    // Sheet closes → tooltip resumes, not marked seen in between.
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
    expect(await CoachMarkService.instance.isSeen('t_sheet'), isFalse);

    // Finishing via the CTA closes the tour and marks it seen.
    await tester.tap(find.text(cta));
    await tester.pumpAndSettle();
    expect(find.text(title), findsNothing);
    expect(CoachMarkService.instance.isTourActive, isFalse);
    expect(await CoachMarkService.instance.isSeen('t_sheet'), isTrue);
  });

  testWidgets('tour does not appear while a covering route is on top',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final context = tester.element(find.text('home'));

    // First-login flow: a full-screen route (onboarding) covers the screen
    // BEFORE the queued tour gets its turn.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('onboarding')),
      ),
    );
    await tester.pumpAndSettle();

    await CoachMarkService.instance
        .maybeStartTour(context, tourId: 't_route', steps: steps);
    await tester.pumpAndSettle();
    expect(find.text(title), findsNothing);
    expect(CoachMarkService.instance.isTourActive, isTrue);

    // Covering route pops → tour finally shows on its own screen.
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);

    await tester.tap(find.text(cta));
    await tester.pumpAndSettle();
    expect(CoachMarkService.instance.isTourActive, isFalse);
  });
}
