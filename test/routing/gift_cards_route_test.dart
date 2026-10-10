import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';
import 'package:qulo_v2/routing/app_router.dart';
import 'package:qulo_v2/routing/route_names.dart';

class _AuthedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _SeenNotifier extends OnboardingSeenNotifier {
  @override
  bool build() => true;
}

/// "Hediye kartlarım" market'in ALTINDA değil, `/profile` altında kardeş rota: go_router bir
/// rotanın yığınına ata rotaların sayfalarını da koyar — iç içe olsaydı gizli bir MarketScreen
/// kurulurdu (GET /market + market_view + tracker; Rainbow'u kapalı ama talebi olan kullanıcıda
/// 403 ve bozuk "Geri").
///
/// Tam router widget testi yığındaki ProfileScreen'i (ağa giden onlarca provider) de kurardı;
/// aynı soru burada gerçek `routerProvider` yapılandırmasının eşleşme zinciriyle sorulur —
/// yığına giren sayfalar tam olarak bu zincirdeki GoRoute'lardır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GoRouter router;

  setUp(() {
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(_AuthedNotifier.new),
      onboardingSeenProvider.overrideWith(_SeenNotifier.new),
    ]);
    addTearDown(container.dispose);
    router = container.read(routerProvider);
    addTearDown(router.dispose);
  });

  List<String?> stackOf(String location) => router.configuration
      .findMatch(Uri.parse(location))
      .routes
      .whereType<GoRoute>()
      .map((route) => route.name)
      .toList();

  test('hediye kartları /profile/gift-cards; yığında MarketScreen rotası YOK', () {
    final location = router.namedLocation(RouteNames.rewardsRedemptions);

    expect(location, '/profile/gift-cards');
    final stack = stackOf(location);
    expect(stack, [RouteNames.profile, RouteNames.rewardsRedemptions]);
    expect(stack, isNot(contains(RouteNames.rewardsMarket)));
  });

  test('market kendi yerinde kalır: /profile/market', () {
    final location = router.namedLocation(RouteNames.rewardsMarket);

    expect(location, '/profile/market');
    expect(stackOf(location), [RouteNames.profile, RouteNames.rewardsMarket]);
  });
}
