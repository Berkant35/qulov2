import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/features/discover/widgets/discover_empty_language.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Dil kapisi yuzunden bos discover. Mesafe sunucuda sinirsiza kadar
/// genisledigi icin ekran "sorun mesafe degil" der ve iki yol sunar: dil
/// tercihini genislet ya da pasaportla baska sehre gec (para yolu).
void main() {
  testWidgets('mesafenin sebep olmadigini soyler', (tester) async {
    final h = _Harness(subscription: SubscriptionInfo.free(), passportActive: false);
    await h.pump(tester);

    final scope = tester.element(find.byType(DiscoverEmptyLanguage)).tr('discover_empty_language_scope');
    expect(find.text(scope), findsOneWidget);
  });

  testWidgets('dil CTA profil duzenlemeye gider', (tester) async {
    final h = _Harness(subscription: SubscriptionInfo.free(), passportActive: false);
    await h.pump(tester);

    final label = tester.element(find.byType(DiscoverEmptyLanguage)).tr('discover_empty_language_cta');
    await tester.tap(find.text(label));

    expect(h.nav.pushed, [RouteNames.editProfile]);
  });

  for (final (name, subscription, passportActive, labelKey, route) in [
    ('ucretsiz kullanici pasaport icin aboneligi gorur', SubscriptionInfo.free(), false,
        'passport_premium_explore_hint', RouteNames.subscription),
    ('Plus kullanici da aboneligi gorur — pasaport yalniz Premium',
        const SubscriptionInfo(plan: 'plus', status: 'active', isActive: true), false,
        'passport_premium_explore_hint', RouteNames.subscription),
    ('Premium (pasaport kapali) pasaportu kesfetmeye gider',
        const SubscriptionInfo(plan: 'premium', status: 'active', isActive: true), false,
        'passport_explore_hint', RouteNames.passport),
    ('pasaport aciksa sehir degistirmeye gider', SubscriptionInfo.free(), true,
        'passport_change_city', RouteNames.passport),
  ]) {
    testWidgets(name, (tester) async {
      final h = _Harness(subscription: subscription, passportActive: passportActive);
      await h.pump(tester);

      final label = tester.element(find.byType(DiscoverEmptyLanguage)).tr(labelKey);
      await tester.tap(find.text(label));

      expect(h.nav.pushed, [route]);
    });
  }
}

class _Harness {
  _Harness({required this.subscription, required this.passportActive});

  final SubscriptionInfo subscription;
  final bool passportActive;
  final nav = _FakeNavigationService();

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        passportProvider.overrideWith(() => _SeededPassport(passportActive)),
        subscriptionProvider.overrideWith(() => _SeededSubscription(subscription)),
        navigationServiceProvider.overrideWithValue(nav),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const Scaffold(body: DiscoverEmptyLanguage()),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }
}

class _SeededPassport extends PassportNotifier {
  _SeededPassport(this._active);
  final bool _active;

  @override
  PassportState build() =>
      _active ? const PassportState(city: 'Bangkok', lat: 13.75, lng: 100.5, isActive: true) : const PassportState();
}

class _SeededSubscription extends SubscriptionNotifier {
  _SeededSubscription(this._info);
  final SubscriptionInfo _info;

  @override
  Future<SubscriptionInfo> build() async => _info;
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
