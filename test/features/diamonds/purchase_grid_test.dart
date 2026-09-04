import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/diamonds/widgets/purchase_grid.dart';
import 'package:qulo_v2/providers/store_prices_provider.dart';

Widget _wrap(Widget child, {required Map<String, String> prices}) => ProviderScope(
      overrides: [storePricesLoaderProvider.overrideWithValue(() async => prices)],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

// NOT: AppLoadingWidget kendi rotasyon animasyonunu sonsuz `repeat()` ile
// calistirir (showGlow=false olsa bile) — bu yuzden agacta AppLoadingWidget
// varken pumpAndSettle() hicbir zaman "sakinlesmez" ve timeout atar. Ayni
// niyeti (future/provider'in cozulmesini beklemek) sinirli pump() ile koruyoruz.
void main() {
  testWidgets('magaza fiyati gosterilir, gomulu USD yok', (tester) async {
    await tester.pumpWidget(_wrap(const PurchaseGrid(), prices: {'qulopurple50': '₺39,99'}));
    await tester.pump();
    await tester.pump();
    expect(find.text('₺39,99'), findsOneWidget);
    expect(find.text('\$0.99'), findsNothing);
  });

  testWidgets('fiyat yoksa iskelet', (tester) async {
    await tester.pumpWidget(_wrap(const PurchaseGrid(), prices: const {}));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppLoadingWidget), findsWidgets);
  });
}
