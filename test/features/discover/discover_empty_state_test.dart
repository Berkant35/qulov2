import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';
import 'package:qulo_v2/features/discover/widgets/discover_empty_state.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Bos discover (cold-start'ta erkeklerin onemli kismi burada). Ekranin iki
/// isi var: yaricapi genisletip tekrar aramak ve pasaport/abonelige yonlendirmek.
/// CTA varyanti para yolu: ucretsiz → abonelik, Premium → pasaport,
/// pasaport acik → sehir degistir.
void main() {
  for (final (name, subscription, passportActive, labelKey, route) in [
    ('ucretsiz kullanici aboneligi gorur', SubscriptionInfo.free(), false,
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

      final label = tester.element(find.byType(DiscoverEmptyState)).tr(labelKey);
      await tester.tap(find.text(label));

      expect(h.nav.pushed, [route]);
    });
  }

  testWidgets('tekrar ara: yaricap kaydedilir ve kartlar yeniden cekilir', (tester) async {
    final h = _Harness(subscription: SubscriptionInfo.free(), passportActive: false);
    await h.pump(tester);

    final label = tester.element(find.byType(DiscoverEmptyState)).tr('search_again');
    await tester.tap(find.text(label));
    await tester.pump();

    expect(h.users.updates, [
      {'match_radius_km': 50},
    ], reason: 'kayitli yaricap yokken varsayilan (AppConstants.defaultMatchRadiusKm)');
    expect(h.match.discoverCalls, 1);
  });
}

class _Harness {
  _Harness({required this.subscription, required this.passportActive});

  final SubscriptionInfo subscription;
  final bool passportActive;
  final nav = _FakeNavigationService();
  final users = _FakeUserRepository();
  final match = _FakeMatchRepository();

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        passportProvider.overrideWith(() => _SeededPassport(passportActive)),
        subscriptionProvider.overrideWith(() => _SeededSubscription(subscription)),
        navigationServiceProvider.overrideWithValue(nav),
        userRepositoryProvider.overrideWithValue(users),
        matchRepositoryProvider.overrideWithValue(match),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: const Scaffold(body: DiscoverEmptyState()),
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
      _active ? const PassportState(city: 'Paris', lat: 48.85, lng: 2.35, isActive: true) : const PassportState();
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

class _FakeUserRepository implements UserRepository {
  final updates = <Map<String, dynamic>>[];

  @override
  Future<Result<UserModel>> updateProfile(Map<String, dynamic> data) async {
    updates.add(data);
    return const Failure(NetworkFailure());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeUserRepository.${invocation.memberName}');
}

class _FakeMatchRepository implements MatchRepository {
  int discoverCalls = 0;

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    discoverCalls++;
    return const Success(DiscoverResponse(cards: [], page: 1, hasMore: false));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeMatchRepository.${invocation.memberName}');
}
