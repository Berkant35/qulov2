import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/format_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/widgets/detail_chips.dart';

/// Kendi profilindeki detay cipleri (`profile_screen` → `DetailChips`).
///
/// Eskiden burc ham kodla ('leo') ve boy sabit '175 cm' ile gosteriliyordu;
/// baskasinin profili (`profile_details_grid`) ayni bilgiyi formatlayiciyla
/// gosteriyordu — kullanici kendi profilinde farkli (ve imperial ise yanlis
/// birimde) goruyordu.
Future<void> _pump(WidgetTester tester, UserDetailsModel details, Locale units) async {
  await FormatManager.instance.configure(units);
  addTearDown(() => FormatManager.instance.configure(const Locale('en')));
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: DetailChips(user: UserModel(id: 'u1', email: 'u1@qulo.test', details: details)),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('burc kodu yerel adla gosterilir, ham kod degil', (tester) async {
    await _pump(tester, const UserDetailsModel(zodiac: 'leo'), const Locale('de', 'DE'));

    expect(find.text('Leo'), findsOneWidget);
    expect(find.text('leo'), findsNothing);
  });

  testWidgets('bilinmeyen burc degeri (serbest metin) oldugu gibi kalir', (tester) async {
    await _pump(tester, const UserDetailsModel(zodiac: 'Yengec'), const Locale('de', 'DE'));

    expect(find.text('Yengec'), findsOneWidget);
  });

  testWidgets('imperial kullaniciya boy feet/inch — "175 cm" degil', (tester) async {
    await _pump(tester, const UserDetailsModel(height: 175), const Locale('en', 'US'));

    expect(find.text('5\'9"'), findsOneWidget);
    expect(find.text('175 cm'), findsNothing);
  });

  testWidgets('metrik kullaniciya boy cm', (tester) async {
    await _pump(tester, const UserDetailsModel(height: 175), const Locale('de', 'DE'));

    expect(find.text('175 cm'), findsOneWidget);
  });
}
