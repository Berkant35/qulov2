import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/onboarding/widgets/paywall_plan_button.dart';
import 'package:qulo_v2/features/onboarding/widgets/premium_suggestion_sheet.dart';
import 'package:qulo_v2/providers/store_prices_provider.dart';

/// Fiyat bilinmezken satın alma butonları dead-end olmasın (review I2).
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

void main() {
  testWidgets('fiyat yoksa Plus/Premium butonları disabled (onTap null)', (tester) async {
    await tester.pumpWidget(_wrap(const PremiumSuggestionSheet(), prices: const {}));
    await tester.pump();
    await tester.pump();

    final buttons = tester.widgetList<PaywallPlanButton>(find.byType(PaywallPlanButton)).toList();
    expect(buttons.length, 2);
    expect(buttons.every((b) => b.onTap == null), isTrue);
  });

  testWidgets('fiyat varsa Plus/Premium butonları enabled (onTap dolu)', (tester) async {
    await tester.pumpWidget(_wrap(
      const PremiumSuggestionSheet(),
      prices: const {
        RevenueCatService.plusProductId: '\$4.99',
        RevenueCatService.premiumProductId: '\$9.99',
      },
    ));
    await tester.pump();
    await tester.pump();

    final buttons = tester.widgetList<PaywallPlanButton>(find.byType(PaywallPlanButton)).toList();
    expect(buttons.length, 2);
    expect(buttons.every((b) => b.onTap != null), isTrue);
  });
}
