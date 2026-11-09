import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';

/// `isInStack`: itilen tam ekran (ör. quiz) ve kabuk içi rota görülür.
/// Çift dokunuşla ikinci quiz'in açılmasını bu kontrol engelliyor.
void main() {
  testWidgets('itilen rota yığında görülür, pop sonrası görülmez', (tester) async {
    final rootKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/discover',
      routes: [
        ShellRoute(
          builder: (_, __, child) => child,
          routes: [
            GoRoute(path: '/discover', name: 'discover', builder: (_, __) => const SizedBox()),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/quiz/:targetId',
          name: 'quiz',
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);
    final nav = NavigationService(router: router, rootNavigatorKey: rootKey);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(nav.isInStack('discover'), isTrue, reason: 'kabuk içi rota');
    expect(nav.isInStack('quiz'), isFalse);

    nav.push('quiz', params: {'targetId': 'u1'});
    await tester.pumpAndSettle();
    expect(nav.isInStack('quiz'), isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect(nav.isInStack('quiz'), isFalse);
  });
}
