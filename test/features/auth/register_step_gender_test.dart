import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_gender.dart';

/// Cinsiyet (eşleşme kovası) ikili: Kadın / Erkek (spec 2026-10-06). "Diğer" kalktı.
void main() {
  Future<List<String>> pump(WidgetTester tester) async {
    final selected = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: RegisterStepGender(onGenderSelected: selected.add, onContinue: () {}),
      ),
    ));
    await tester.pump();
    return selected;
  }

  testWidgets('yalnız iki seçenek: Kadın ve Erkek; Diğer yok', (tester) async {
    await pump(tester);
    final ctx = tester.element(find.byType(RegisterStepGender));
    expect(find.text(ctx.tr('man')), findsOneWidget);
    expect(find.text(ctx.tr('woman')), findsOneWidget);
    expect(find.text(ctx.tr('other')), findsNothing);
  });

  testWidgets('seçim MAN / WOMAN değerini verir', (tester) async {
    final selected = await pump(tester);
    final ctx = tester.element(find.byType(RegisterStepGender));
    await tester.tap(find.text(ctx.tr('woman')));
    await tester.tap(find.text(ctx.tr('man')));
    expect(selected, ['WOMAN', 'MAN']);
  });
}
