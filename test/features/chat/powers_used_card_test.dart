import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/chat/widgets/powers_used_card.dart';

Future<void> _pump(WidgetTester tester, List<String> powers) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    localizationsDelegates: const [AppLocalizationsDelegate()],
    supportedLocales: const [Locale('en')],
    locale: const Locale('en'),
    home: Scaffold(body: PowersUsedCard(powers: powers)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('güç başına tek çip, tekrar sayısıyla; etiket çevrili (ham HALF/SKIP yok)', (tester) async {
    await _pump(tester, const ['HALF', 'SKIP', 'HALF']);

    expect(find.byType(Chip), findsNWidgets(2));
    expect(find.text('50/50 ×2'), findsOneWidget);
    expect(find.text('Mark Correct'), findsOneWidget);
    expect(find.textContaining('HALF'), findsNothing);
    expect(find.textContaining('SKIP'), findsNothing);
  });

  testWidgets('bilinmeyen güç adı çip çizmez (yeni sunucu, eski uygulama)', (tester) async {
    await _pump(tester, const ['HALF', 'FUTURE_POWER']);

    expect(find.byType(Chip), findsOneWidget);
    expect(find.text('50/50'), findsOneWidget);
  });
}
