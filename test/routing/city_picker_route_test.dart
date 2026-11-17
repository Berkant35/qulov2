import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulo_v2/features/location/screens/city_picker_screen.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';
import 'package:qulo_v2/routing/app_router.dart';
import 'package:qulo_v2/routing/route_names.dart';

class _GuestNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _SeenNotifier extends OnboardingSeenNotifier {
  _SeenNotifier(this.seen);
  final bool seen;

  @override
  bool build() => seen;
}

/// Kayıt akışında konum adımı hesap oluşmadan ÖNCE gelir. "Şehir seç" şehir seçiciyi
/// (`/city-picker`, `extra: true`) açar; router'ın oturumsuz kullanıcı kuralı bu rotayı
/// landing'e atarsa kullanıcı kayıttan düşer (2.0.19 build 106'da gönderim öncesi yakalandı).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter routerFor({required bool onboardingSeen}) {
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(_GuestNotifier.new),
      onboardingSeenProvider.overrideWith(() => _SeenNotifier(onboardingSeen)),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    return router;
  }

  Future<String?> redirectFor(WidgetTester tester, GoRouter router, String location, {Object? extra}) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox.shrink();
    }));
    final state = GoRouterState(
      router.configuration,
      uri: Uri.parse(location),
      matchedLocation: location,
      fullPath: location,
      pathParameters: const {},
      pageKey: ValueKey(location),
      extra: extra,
    );
    return await router.configuration.topRedirect(context, state);
  }

  testWidgets('oturumsuz + seçim kipi: şehir seçici açılır (yönlendirme yok)', (tester) async {
    final router = routerFor(onboardingSeen: true);
    expect(await redirectFor(tester, router, '/city-picker', extra: true), isNull);
  });

  testWidgets('oturumsuz + seçim kipi, tanıtım görülmemiş olsa da açılır', (tester) async {
    final router = routerFor(onboardingSeen: false);
    expect(await redirectFor(tester, router, '/city-picker', extra: true), isNull);
  });

  testWidgets('oturumsuz + seçim kipi DEĞİL: landing (ağa yazan kip hesap ister)', (tester) async {
    final router = routerFor(onboardingSeen: true);
    expect(await redirectFor(tester, router, '/city-picker'), '/auth/landing');
  });

  testWidgets('oturumsuz kullanıcı başka rotaya yine giremez', (tester) async {
    final router = routerFor(onboardingSeen: true);
    expect(await redirectFor(tester, router, '/discover', extra: true), '/auth/landing');
  });

  testWidgets('rota extra == true ile seçim kipinde kurulur', (tester) async {
    final router = routerFor(onboardingSeen: true);
    expect(router.namedLocation(RouteNames.cityPicker), '/city-picker');
    final route = router.configuration.findMatch(Uri.parse('/city-picker')).routes.whereType<GoRoute>().single;

    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox.shrink();
    }));
    GoRouterState stateWith(Object? extra) => GoRouterState(
          router.configuration,
          uri: Uri.parse('/city-picker'),
          matchedLocation: '/city-picker',
          fullPath: '/city-picker',
          pathParameters: const {},
          pageKey: const ValueKey('city-picker'),
          extra: extra,
        );

    expect((route.builder!(context, stateWith(true)) as CityPickerScreen).selectOnly, isTrue);
    expect((route.builder!(context, stateWith(null)) as CityPickerScreen).selectOnly, isFalse);
  });
}
