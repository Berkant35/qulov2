import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_controller.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_overlay.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/quiz/coach/quiz_power_coach_marks.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../helpers/fixed_user_notifier.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );

/// Gerçek quiz güç turu (ilk quiz öncesi kart: cüzdan satırı + 6 güç + "Güçleri dene").
Widget _quizTour(CoachMarkController controller, {required String locale}) => ProviderScope(
      overrides: [
        powerDemoEnabledProvider.overrideWithValue(true),
        userProvider.overrideWith(
          () => FixedUserNotifier(const UserModel(id: 'u1', email: 'u1@qulo.test', purpleDiamonds: 30)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale(locale)],
        locale: Locale(locale),
        home: Scaffold(body: CoachMarkOverlay(controller: controller)),
      ),
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
    c.onFinished = ({required skipped, required stepIndex}) => finished = true;

    await tester.pumpWidget(_wrap(CoachMarkOverlay(controller: c)));
    await tester.pump();

    expect(c.index, 0);
    // Tap the CTA button (AppButton renders its label text).
    await tester.tap(find.text(AppLocalizations(const Locale('en')).get('coach_cta_next')));
    await tester.pump();
    expect(c.index, 1);
    expect(finished, isFalse);
  });

  // Ruling 16: kart gövdesi uzun içerikte kayar; başlık, kapatma ve birincil düğme hep görünür.
  // Ölçüm (final inceleme, SF fontu): SE tr 1.5'te 19 px, ru 1.3'te 56 px taşma, "Anladım" kırpılıyordu.
  for (final (locale, scale) in const [('tr', 1.5), ('ru', 1.3), ('en', 1.5)]) {
    testWidgets('375×667 $locale textScale $scale quiz güç turu: taşma yok, başlık/kapatma/CTA dokunulabilir',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 20);
      tester.view.viewPadding = const FakeViewPadding(top: 20);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final l10n = AppLocalizations(Locale(locale));
      final controller = CoachMarkController(steps: buildQuizPowerCoachSteps());
      var finished = false;
      controller.onFinished = ({required skipped, required stepIndex}) => finished = !skipped;

      await tester.pumpWidget(_quizTour(controller, locale: locale));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull, reason: 'kart taşmaz');
      const screen = Rect.fromLTRB(0, 20, 375, 667);
      for (final finder in [
        find.text(l10n.get('coach_quiz_powers_title')),
        find.text(l10n.get('coach_cta_got_it')),
        find.byIcon(Icons.close),
      ]) {
        expect(finder.hitTestable(), findsOneWidget, reason: '$finder dokunulabilir');
        final rect = tester.getRect(finder);
        expect(screen.contains(rect.topLeft) && screen.contains(rect.bottomRight), isTrue,
            reason: '$finder ekranda: $rect');
      }
      // "Güçleri dene" gövdenin sonunda: kaydırınca ulaşılır.
      final tryPowers = find.text(l10n.get('power_demo_try'));
      await tester.ensureVisible(tryPowers);
      await tester.pump();
      expect(tryPowers.hitTestable(), findsOneWidget);

      await tester.tap(find.text(l10n.get('coach_cta_got_it')));
      await tester.pump();
      expect(finished, isTrue, reason: 'birincil düğme turu bitirir');
    });
  }

  testWidgets('kısa içerikte kart kaymaz ve içeriği kadar yer kaplar (diğer turlar aynı)', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = CoachMarkController(steps: const [
      CoachMarkStep(
          titleKey: 'coach_discover_intro_title',
          bodyKey: 'coach_discover_intro_body',
          ctaKey: 'coach_cta_next'),
    ]);

    await tester.pumpWidget(_wrap(CoachMarkOverlay(controller: c)));
    await tester.pump();

    final scroll = find.byType(Scrollable);
    if (scroll.evaluate().isNotEmpty) {
      expect(tester.state<ScrollableState>(scroll).position.maxScrollExtent, 0, reason: 'kaydırılacak içerik yok');
    }
    final card = tester.getRect(find.ancestor(
      of: find.text(AppLocalizations(const Locale('en')).get('coach_discover_intro_title')),
      matching: find.byType(Container),
    ).first);
    expect(card.height, lessThan(667 / 2), reason: 'kısa kart ekranı doldurmaz');
    expect(card.center.dy, moreOrLessEquals(667 / 2, epsilon: 1), reason: 'çapasız kart ortada');
  });
}
