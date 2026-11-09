import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/features/location/mixins/country_label_mixin.dart';

import '../../../helpers/translations.dart';

class _Labels with CountryLabelMixin {}

void main() {
  test('bayrak: ISO kodu → bölgesel gösterge harfleri; bozuk kod boş', () {
    expect(CountryLabelMixin.countryFlag('TR'), '🇹🇷');
    expect(CountryLabelMixin.countryFlag('JP'), '🇯🇵');
    expect(CountryLabelMixin.countryFlag('tr'), '');
    expect(CountryLabelMixin.countryFlag('TUR'), '');
  });

  test('çevirisi olan her ülkenin adı 18 dilde var', () {
    for (final entry in allTranslations.entries) {
      for (final code in CountryLabelMixin.translatedCountries) {
        expect(entry.value['country_name_${code.toLowerCase()}'], isNotNull, reason: '${entry.key} $code');
      }
    }
  });

  testWidgets('bilinen ülke dilde adla, bilinmeyen kodla gösterilir', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    await tester.pump();

    expect(_Labels().countryLabel(ctx, 'IT'), '🇮🇹 Italy');
    expect(_Labels().countryLabel(ctx, 'DE'), '🇩🇪 DE');
  });
}
