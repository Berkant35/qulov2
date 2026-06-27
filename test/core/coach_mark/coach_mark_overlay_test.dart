import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_controller.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_overlay.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders title and advances on CTA tap', (tester) async {
    final c = CoachMarkController(steps: const [
      CoachMarkStep(
          titleKey: 'coach_discover_intro_title',
          bodyKey: 'coach_discover_intro_body',
          ctaKey: 'coach_cta_next'),
      CoachMarkStep(
          titleKey: 'coach_discover_solve_title',
          bodyKey: 'coach_discover_solve_body',
          ctaKey: 'coach_cta_start'),
    ]);
    var finished = false;
    c.onFinished = () => finished = true;

    await tester.pumpWidget(_wrap(CoachMarkOverlay(controller: c)));
    await tester.pump();

    expect(c.index, 0);
    // Tap the CTA button (AppButton renders its label text).
    await tester.tap(find.text(AppLocalizations(const Locale('en')).get('coach_cta_next')));
    await tester.pump();
    expect(c.index, 1);
    expect(finished, isFalse);
  });
}
