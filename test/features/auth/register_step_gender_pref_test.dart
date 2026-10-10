import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_gender_pref.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_checkbox.dart';

class _Taps {
  int continued = 0;
  int declined = 0;
  final consent = <bool>[];
}

Future<_Taps> _pump(WidgetTester tester, Widget Function(_Taps) home) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taps = _Taps();
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
      child: child!,
    ),
    home: Scaffold(body: SafeArea(child: home(taps))),
  ));
  await tester.pump();
  return taps;
}

Widget _step(_Taps t, {bool granted = true}) => RegisterStepGenderPref(
      selectedValue: granted ? 'MAN' : null,
      consentGranted: granted,
      onSelected: (_) {},
      onConsentChanged: t.consent.add,
      onDeclineConsent: () => t.declined++,
      onOpenPolicy: () {},
      onContinue: () => t.continued++,
    );

void main() {
  // KVKK adımı kaydırması kapalı PageView içinde yaşar; küçük ekran + büyük yazıda
  // taşarsa "devam" ve "rıza vermeden devam" kırpılıp adım kullanılamaz olurdu.
  testWidgets('375x667 + yazı 1.3x: taşma yok, iki düğme kaydırınca erişilir ve çalışır', (tester) async {
    final taps = await _pump(tester, _step);
    expect(tester.takeException(), isNull);

    final ctx = tester.element(find.byType(RegisterStepGenderPref));
    final cont = find.widgetWithText(AppButton, ctx.tr('register_gender_pref_continue'));
    final decline = find.widgetWithText(TextButton, ctx.tr('pref_consent_continue_without'));
    expect(cont, findsOneWidget);
    expect(decline, findsOneWidget);

    await tester.ensureVisible(decline);
    await tester.pump();
    await tester.tap(decline);
    expect(taps.declined, 1);

    await tester.ensureVisible(cont);
    await tester.pump();
    await tester.tap(cont);
    expect(taps.continued, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('geniş ekranda düğmeler altta kalır (Spacer korunur)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final taps = _Taps();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: _step(taps)),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final bottom = tester.getBottomLeft(find.byType(TextButton).last).dy;
    expect(bottom, greaterThan(1400));
  });

  group('PrefConsentCheckbox', () {
    testWidgets('etiket metnine dokunmak kutuyu değiştirir; tek anlamsal düğüm checked taşır', (tester) async {
      final handle = tester.ensureSemantics();
      final taps = await _pump(
        tester,
        (t) => PrefConsentCheckbox(value: false, onChanged: t.consent.add, onOpenPolicy: () {}),
      );
      final ctx = tester.element(find.byType(PrefConsentCheckbox));

      await tester.tap(find.text(ctx.tr('pref_consent_checkbox')));
      expect(taps.consent, [true]);

      final node = tester.getSemantics(find.text(ctx.tr('pref_consent_checkbox')));
      // Birleşik veri: etiket + onay kutusu durumu aynı düğümde.
      final data = node.getSemanticsData();
      expect(data.label, contains(ctx.tr('pref_consent_checkbox')));
      expect(data.flagsCollection.hasCheckedState, isTrue);
      expect(data.flagsCollection.isChecked, isFalse);
      handle.dispose();
    });

    testWidgets('politika düğmesi kutuyu DEĞİŞTİRMEZ, yalnız politikayı açar', (tester) async {
      var opened = 0;
      final taps = await _pump(
        tester,
        (t) => PrefConsentCheckbox(value: false, onChanged: t.consent.add, onOpenPolicy: () => opened++),
      );
      final ctx = tester.element(find.byType(PrefConsentCheckbox));

      await tester.tap(find.text(ctx.tr('pref_consent_read_policy')));
      expect(opened, 1);
      expect(taps.consent, isEmpty);
    });
  });
}
