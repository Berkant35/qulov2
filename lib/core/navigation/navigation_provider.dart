import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/routing/app_router.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/core/navigation/observers/logging_observer.dart';
import 'package:qulo_v2/core/navigation/observers/analytics_observer.dart';

final navigationServiceProvider = Provider<NavigationService>((ref) {
  final router = ref.read(routerProvider);
  return NavigationService(
    router: router,
    rootNavigatorKey: rootNavigatorKey,
    observers: [LoggingObserver(), AnalyticsNavigationObserver()],
  );
});
