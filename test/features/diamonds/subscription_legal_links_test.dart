import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/core/services/url_launcher_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/diamonds/widgets/subscription_legal_links.dart';
import 'package:qulo_v2/features/onboarding/widgets/premium_suggestion_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/store_prices_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:url_launcher/url_launcher.dart';

/// Otomatik yenilenen abonelik satilan her yuzeyde Kullanim Kosullari (EULA)
/// ve Gizlilik linki zorunlu (App Store 3.1.2(c)); eksikse surum reddedilir.
/// Uc satis yuzeyi: `PaywallBottomSheetContent`, `SubscriptionComparisonScreen`
/// ve quiz sonrasi acilan `PremiumSuggestionSheet` — sonuncusunda link YOKTU.
void main() {
  group('linkler tiklanabilir', () {
    testWidgets('Kullanim Kosullari Apple standart EULA\'sini acar', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.wrap(const SubscriptionLegalLinks()));
      await tester.pump(); // yerellestirme delegesi asenkron yuklenir

      await tester.tap(_links().first);

      expect(h.urls.launched, ['https://www.apple.com/legal/internet-services/itunes/dev/stdeula/']);
    });

    testWidgets('Gizlilik Politikasi uygulama ici sayfaya gider', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.wrap(const SubscriptionLegalLinks()));
      await tester.pump(); // yerellestirme delegesi asenkron yuklenir

      await tester.tap(_links().last);

      expect(h.nav.pushed, [RouteNames.privacyPolicy]);
    });
  });

  group('satis yuzeyleri linkleri gosterir', () {
    testWidgets('quiz sonrasi Premium onerisi (PremiumSuggestionSheet)', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.wrap(const PremiumSuggestionSheet()));
      await tester.pump();

      expect(find.byType(SubscriptionLegalLinks), findsOneWidget);
    });

    testWidgets('paywall alt sayfasi (PaywallBottomSheetContent)', (tester) async {
      final h = _Harness();
      await tester.pumpWidget(h.wrap(const PaywallBottomSheetContent(trigger: 'test')));
      await tester.pump();

      expect(find.byType(SubscriptionLegalLinks), findsOneWidget);
    });
  });
}

Finder _links() =>
    find.descendant(of: find.byType(SubscriptionLegalLinks), matching: find.byType(GestureDetector));

class _Harness {
  final urls = _FakeUrlLauncher();
  final nav = _FakeNavigationService();

  Widget wrap(Widget child) => ProviderScope(
        overrides: [
          storePricesLoaderProvider.overrideWithValue(() async => const <String, String>{}),
          urlLauncherManagerProvider.overrideWithValue(urls),
          navigationServiceProvider.overrideWithValue(nav),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: const [AppLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
}

class _FakeUrlLauncher implements UrlLauncherManager {
  final launched = <String>[];

  @override
  Future<bool> launch(String url, {LaunchMode mode = LaunchMode.externalApplication}) async {
    launched.add(url);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeUrlLauncher.${invocation.memberName}');
}

class _FakeNavigationService implements NavigationService {
  final pushed = <String>[];

  @override
  Future<T?> push<T extends Object?>(String name, {Map<String, String>? params, Object? extra}) async {
    pushed.add(name);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNavigationService.${invocation.memberName}');
}
