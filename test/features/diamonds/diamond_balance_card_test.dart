import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamond_balance_card.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(body: child),
  ));
  await tester.pump();
}

Finder _icon(DiamondType type) =>
    find.byWidgetPredicate((w) => w is DiamondIcon && w.type == type);

void main() {
  testWidgets('rainbowCount verilmezse yalnız mor ve yeşil', (tester) async {
    await _pump(tester, const DiamondBalanceCard(greenCount: 4, purpleCount: 75));

    expect(_icon(DiamondType.purple), findsOneWidget);
    expect(_icon(DiamondType.green), findsOneWidget);
    expect(_icon(DiamondType.rainbow), findsNothing);
    expect(find.text('Rainbow Diamonds'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rainbowCount verilirse üçüncü bölüm', (tester) async {
    await _pump(tester, const DiamondBalanceCard(greenCount: 4, purpleCount: 75, rainbowCount: 12));

    expect(_icon(DiamondType.rainbow), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Rainbow Diamonds'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
