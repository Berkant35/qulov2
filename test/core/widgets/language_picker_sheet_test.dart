import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';

/// Dil seçici alt sayfası: 18 çip küçük ekranda tavanı aşınca taşmamalı,
/// çipler kaydırılmalı ve Kaydet butonu her zaman görünür kalmalı.
/// (16→18 dil geçişinde iPhone SE yüksekliğinde RenderFlex taşması riski.)
Widget _wrap(Widget child, {required double height}) => MaterialApp(
  theme: AppTheme.dark,
  localizationsDelegates: const [AppLocalizationsDelegate()],
  supportedLocales: const [Locale('en')],
  locale: const Locale('en'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(height: height, width: 375, child: child),
    ),
  ),
);

Widget _wrapLoose(Widget child, {required double maxHeight}) => MaterialApp(
  theme: AppTheme.dark,
  localizationsDelegates: const [AppLocalizationsDelegate()],
  supportedLocales: const [Locale('en')],
  locale: const Locale('en'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 375),
        child: child,
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'dar yükseklikte taşmaz, tüm çipler kaydırılabilir, Kaydet görünür',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LanguagePickerSheet(
            selectedLanguages: ['en'],
            multiSelect: false,
          ),
          height: 320,
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
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(320));
      // Bütün diller listede (kaydırılabilir alanda olsa da widget ağacında).
      expect(
        find.byType(FilterChip, skipOffstage: false),
        findsNWidgets(AppConstants.supportedQuestionLocales.length),
      );
      // Son çip gerçekten kaydırılarak görünür oluyor (scroll view kilitlenmemiş).
      final lastLocale = AppConstants.supportedQuestionLocales.last;
      final lastName = AppLocalizations(
        const Locale('en'),
      ).get('locale_$lastLocale');
      final lastChip = find.textContaining(lastName, skipOffstage: false);
      await tester.scrollUntilVisible(
        lastChip,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining(lastName), findsOneWidget);
    },
  );

  testWidgets(
    'yeterli yükseklikte içerik kadar yer kaplar (shrink-wrap bozulmaz)',
    (tester) async {
      // Varsayılan test yüzeyi 800x600; gevşek 2400px sınırında sheet içerik kadar kalmalı.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrapLoose(
          const LanguagePickerSheet(
            selectedLanguages: ['en'],
            multiSelect: false,
          ),
          maxHeight: 2400,
        ),
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
