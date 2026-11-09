import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_screen.dart';
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

/// `power-demo` auth SONRASI route'tur (market ▶ ve ilk quiz öncesi güç kartı): kök navigator'da,
/// altında hiçbir sayfa kurmayan tek başına bir rota. Auth öncesi demo carousel'in içinde gömülüdür
/// (yeni auth-öncesi route yok — redirect'e takılırdı).
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

  GoRoute demoRoute() =>
      router.configuration.findMatch(Uri.parse('/power-demo')).routes.whereType<GoRoute>().single;

  test('power-demo /power-demo; yığında yalnız demo sayfası, kök navigator', () {
    expect(router.namedLocation(RouteNames.powerDemo), '/power-demo');

    final route = demoRoute();
    expect(route.name, RouteNames.powerDemo);
    expect(route.parentNavigatorKey, rootNavigatorKey, reason: 'tam ekran, alt gezinme çubuğu yok');
  });

  for (final (name, extra, expected) in [
    ('market', PowerDemoEntryPoint.market, PowerDemoEntryPoint.market),
    ('quiz_intro', PowerDemoEntryPoint.quizIntro, PowerDemoEntryPoint.quizIntro),
    ('extra yok → varsayılan market', null, PowerDemoEntryPoint.market),
    ('tanınmayan extra → varsayılan market', 'quiz_intro', PowerDemoEntryPoint.market),
  ]) {
    testWidgets('extra: $name', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (c) {
        context = c;
        return const SizedBox.shrink();
      }));

      final state = GoRouterState(
        router.configuration,
        uri: Uri.parse('/power-demo'),
        matchedLocation: '/power-demo',
        fullPath: '/power-demo',
        pathParameters: const {},
        pageKey: const ValueKey('power-demo'),
        extra: extra,
      );
      final screen = demoRoute().builder!(context, state);

      expect(screen, isA<PowerDemoScreen>());
      expect((screen as PowerDemoScreen).entryPoint, expected);
    });
  }
}
