import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/widgets/rescue_cards.dart';

/// İlk quiz ikinci şansı: ücretli SKIP satırının yerine belirgin "ücretsiz"
/// kart çıkar ve SKIP kurtarmasını çağırır. Eski veride ücretsiz SKIP fark
/// edilmemişti — fiyat rozetiyle aynı satırda durmamalı.
void main() {
  final en = AppLocalizations(const Locale('en'));
  const skip = RescuePowerOption(type: PowerType.skip, inventoryCount: 0, diamondCost: 15);

  Future<List<String>> pump(WidgetTester tester, {required bool free}) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: RescueCards(
            freeSecondChance: free,
            skipOption: skip,
            onRescue: calls.add,
            onDeclineRescue: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('ikinci şans: ücretsiz kart görünür, ücretli SKIP satırı yok', (tester) async {
    final calls = await pump(tester, free: true);

    expect(find.text(en.get('quiz_second_chance_title')), findsOneWidget);
    expect(find.text(en.get('quiz_second_chance_free_badge')), findsOneWidget);
    expect(find.text(en.get('quiz_rescue_skip')), findsNothing);
    expect(find.text('15'), findsNothing, reason: 'bedava hakta fiyat gösterilmez');

    await tester.tap(find.text(en.get('quiz_second_chance_cta')));
    await tester.pumpAndSettle();
    expect(calls, ['SKIP']);
  });

  testWidgets('ikinci şans yok: ücretli SKIP satırı ve fiyatı', (tester) async {
    await pump(tester, free: false);

    expect(find.text(en.get('quiz_second_chance_title')), findsNothing);
    expect(find.text(en.get('quiz_rescue_skip')), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
  });
}
