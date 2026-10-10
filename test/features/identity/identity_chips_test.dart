import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/features/identity/widgets/identity_chips.dart';

Future<String Function(String)> _pump(WidgetTester tester, VisibleIdentityModel identity) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: IdentityChips(identity: identity)),
    ),
  );
  await tester.pump();
  final ctx = tester.element(find.byType(IdentityChips));
  return (String k) => ctx.tr(k);
}

void main() {
  testWidgets('iki grubun etiketlerini çevirisiyle gösterir', (tester) async {
    final tr = await _pump(
      tester,
      const VisibleIdentityModel(genderLabels: ['non_binary'], orientationLabels: ['gay']),
    );
    expect(find.text(tr(IdentityLabels.orientationKey('gay'))), findsOneWidget);
    expect(find.text(tr(IdentityLabels.genderKey('non_binary'))), findsOneWidget);
  });

  testWidgets('"questioning" iki grupta da seçiliyse her grubun kendi çipi çizilir', (
    tester,
  ) async {
    final tr = await _pump(
      tester,
      const VisibleIdentityModel(genderLabels: ['questioning'], orientationLabels: ['questioning']),
    );
    // Anahtarlar gruba göre önekli; metin iki grupta da aynı — tekilleştirilmemeli.
    expect(tr(IdentityLabels.genderKey('questioning')), 'Questioning');
    expect(tr(IdentityLabels.orientationKey('questioning')), 'Questioning');
    expect(find.text('Questioning'), findsNWidgets(2));
  });

  testWidgets('"questioning" yalnız bir grupta seçiliyse tek çip çizilir', (tester) async {
    await _pump(tester, const VisibleIdentityModel(genderLabels: ['questioning']));
    expect(find.text('Questioning'), findsOneWidget);
  });

  testWidgets('boş model hiçbir şey çizmez', (tester) async {
    await _pump(tester, const VisibleIdentityModel());
    expect(find.byType(Wrap), findsNothing);
  });
}
