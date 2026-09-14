import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';

/// Dil seçici alt sayfası: 18 çip küçük ekranda tavanı aşınca taşmamalı,
/// çipler kaydırılmalı ve Kaydet butonu her zaman görünür kalmalı.
/// (16→18 dil geçişinde iPhone SE yüksekliğinde RenderFlex taşması riski.)
///
/// [tight] true iken yükseklik sabitlenir (gerçek alt sayfa tavanı gibi);
/// false iken yalnızca üst sınır verilir (shrink-wrap davranışı ölçülür).
Widget _host(Widget child, {required double maxHeight, bool tight = false}) =>
    MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: tight ? maxHeight : 0,
              maxHeight: maxHeight,
              maxWidth: 375,
            ),
            child: child,
          ),
        ),
      ),
    );

Finder _chips() => find.descendant(
  of: find.byType(LanguagePickerSheet),
  matching: find.byType(FilterChip),
  skipOffstage: false,
);

void main() {
  testWidgets('dar yükseklikte taşmaz, tüm çipler kaydırılabilir, Kaydet görünür', (
    tester,
  ) async {
    const height = 320.0;
    await tester.pumpWidget(
      _host(
        const LanguagePickerSheet(selected: 'en'),
        maxHeight: height,
        tight: true,
      ),
    );
    await tester.pump();

    expect(
      tester.takeException(),
      isNull,
      reason: 'RenderFlex taşması olmamalı',
    );
    final save = find.byType(FilledButton);
    expect(save, findsOneWidget);
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(height));
    // Bütün diller bu sayfanın çipleri olarak ağaçta (kaydırılabilir alanda olsa da).
    expect(
      _chips(),
      findsNWidgets(AppConstants.supportedQuestionLocales.length),
    );
    // Son çip başta görünür alanın dışında, kaydırınca sayfanın sınırları içine giriyor.
    final lastName = AppLocalizations(
      const Locale('en'),
    ).get('locale_${AppConstants.supportedQuestionLocales.last}');
    final lastChip = find.ancestor(
      of: find.textContaining(lastName, skipOffstage: false),
      matching: find.byType(FilterChip),
    );
    final sheetRect = tester.getRect(find.byType(LanguagePickerSheet));
    expect(
      tester.getRect(lastChip).bottom,
      greaterThan(sheetRect.bottom),
      reason: 'test anlamlı olsun diye son çip başta sığmamalı',
    );
    await tester.scrollUntilVisible(
      lastChip,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    final visible = tester.getRect(lastChip);
    expect(visible.top, greaterThanOrEqualTo(sheetRect.top));
    expect(visible.bottom, lessThanOrEqualTo(sheetRect.bottom));
  });

  testWidgets('çipe dokunmak seçimi taşır, Kaydet seçilen kodu döndürür', (
    tester,
  ) async {
    String? popped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: LanguagePickerSheet(selected: 'en'),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(); // l10n delegate asenkron yüklenir
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final trName = AppLocalizations(const Locale('en')).get('locale_tr');
    await tester.tap(find.textContaining(trName));
    await tester.pump();
    final selectedChips = tester
        .widgetList<FilterChip>(_chips())
        .where((c) => c.selected)
        .length;
    expect(selectedChips, 1, reason: 'tek seçim: önceki seçim düşmeli');

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(popped, 'tr');
  });

  testWidgets(
    'yeterli yükseklikte içerik kadar yer kaplar (shrink-wrap bozulmaz)',
    (tester) async {
      // Varsayılan test yüzeyi 800x600; gevşek 2400px sınırında sheet içerik kadar kalmalı.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _host(const LanguagePickerSheet(selected: 'en'), maxHeight: 2400),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final sheetHeight = tester
          .getSize(find.byType(LanguagePickerSheet))
          .height;
      expect(sheetHeight, lessThan(2400));
      expect(sheetHeight, greaterThan(320));
    },
  );
}
