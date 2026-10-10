import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/onboarding/widgets/setup_gender_pref_card.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_checkbox.dart';

class _Taps {
  final selected = <String>[];
  final consent = <bool>[];
  int declined = 0;
  int policy = 0;
}

Future<_Taps> _pump(
  WidgetTester tester, {
  bool consentGranted = false,
  bool isComplete = false,
  bool isProcessing = false,
  double textScale = 1.0,
}) async {
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
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SetupGenderPrefCard(
            selectedValue: null,
            isComplete: isComplete,
            isProcessing: isProcessing,
            consentGranted: consentGranted,
            onConsentChanged: taps.consent.add,
            onSelect: taps.selected.add,
            onDecline: () => taps.declined++,
            onOpenPolicy: () => taps.policy++,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  return taps;
}

BuildContext _ctx(WidgetTester tester) => tester.element(find.byType(SetupGenderPrefCard));

void main() {
  // KVKK m.6: rıza işaretlenmeden tercih kaydedilemez; seçenekler kilitli olmalı.
  group('SetupGenderPrefCard — rıza kapısı', () {
    testWidgets('rıza işaretsiz: MAN/WOMAN/BOTH dokunuşu onSelect çağırmaz', (tester) async {
      final taps = await _pump(tester);
      final ctx = _ctx(tester);

      for (final key in ['setup_gender_pref_men', 'setup_gender_pref_women', 'setup_gender_pref_both']) {
        await tester.tap(find.text(ctx.tr(key)));
      }
      expect(taps.selected, isEmpty);
    });

    testWidgets('rıza işaretli: MAN dokunuşu onSelect(MAN) tam bir kez çağırır', (tester) async {
      final taps = await _pump(tester, consentGranted: true);
      final ctx = _ctx(tester);

      await tester.tap(find.text(ctx.tr('setup_gender_pref_men')));
      expect(taps.selected, ['MAN']);
    });

    testWidgets('rıza işaretli: WOMAN ve BOTH doğru değeri taşır', (tester) async {
      final taps = await _pump(tester, consentGranted: true);
      final ctx = _ctx(tester);

      await tester.tap(find.text(ctx.tr('setup_gender_pref_women')));
      await tester.tap(find.text(ctx.tr('setup_gender_pref_both')));
      expect(taps.selected, ['WOMAN', 'BOTH']);
    });

    testWidgets('onay satırına dokunmak onConsentChanged(true) çağırır', (tester) async {
      final taps = await _pump(tester);
      final ctx = _ctx(tester);

      await tester.tap(find.text(ctx.tr('pref_consent_checkbox')));
      expect(taps.consent, [true]);
    });

    testWidgets('politika düğmesi onOpenPolicy çağırır, rızayı DEĞİŞTİRMEZ', (tester) async {
      final taps = await _pump(tester);
      final ctx = _ctx(tester);

      await tester.tap(find.text(ctx.tr('pref_consent_read_policy')));
      expect(taps.policy, 1);
      expect(taps.consent, isEmpty);
    });
  });

  group('SetupGenderPrefCard — rıza vermeden devam', () {
    testWidgets('düğme onDecline çağırır (rıza işaretsizken de)', (tester) async {
      final taps = await _pump(tester);
      final ctx = _ctx(tester);

      await tester.tap(find.widgetWithText(TextButton, ctx.tr('pref_consent_continue_without')));
      expect(taps.declined, 1);
    });

    testWidgets('isProcessing: düğme çalışmaz, seçenekler de kilitli', (tester) async {
      final taps = await _pump(tester, consentGranted: true, isProcessing: true);
      final ctx = _ctx(tester);

      final decline = find.widgetWithText(TextButton, ctx.tr('pref_consent_continue_without'));
      expect(tester.widget<TextButton>(decline).onPressed, isNull);
      await tester.tap(decline, warnIfMissed: false);
      await tester.tap(find.text(ctx.tr('setup_gender_pref_men')));
      expect(taps.declined, 0);
      expect(taps.selected, isEmpty);
    });
  });

  group('SetupGenderPrefCard — tamamlanmış hali', () {
    testWidgets('isComplete: onay kutusu, seçenekler ve rıza vermeden devam düğmesi yok', (tester) async {
      await _pump(tester, isComplete: true);
      final ctx = _ctx(tester);

      expect(find.byType(PrefConsentCheckbox), findsNothing);
      expect(find.text(ctx.tr('setup_gender_pref_men')), findsNothing);
      expect(find.text(ctx.tr('setup_gender_pref_women')), findsNothing);
      expect(find.text(ctx.tr('setup_gender_pref_both')), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.text(ctx.tr('setup_gender_pref_done')), findsOneWidget);
    });
  });

  // Kart yatayda taşarsa (üç seçenek tek satırda) küçük ekran + büyük yazıda kırpılır.
  group('SetupGenderPrefCard — küçük ekran', () {
    testWidgets('375x667 + yazı 1.3x: taşma yok, rıza vermeden devam kaydırınca erişilir', (tester) async {
      final taps = await _pump(tester, consentGranted: true, textScale: 1.3);
      expect(tester.takeException(), isNull);

      final ctx = _ctx(tester);
      final decline = find.widgetWithText(TextButton, ctx.tr('pref_consent_continue_without'));
      await tester.ensureVisible(decline);
      await tester.pump();
      await tester.tap(decline);
      expect(taps.declined, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
