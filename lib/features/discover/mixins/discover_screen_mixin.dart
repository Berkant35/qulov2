import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';

mixin DiscoverScreenMixin on ConsumerState<DiscoverScreen> {
  final Stopwatch sessionStopwatch = Stopwatch()..start();
  int swipesRight = 0;
  int swipesLeft = 0;
  int profilesViewed = 0;
  bool emptyLogged = false;

  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.discoverSessionStart);
    Future.microtask(() => initLocationAndDiscover());
    listenLocationRecovery();
  }

  void disposeMixin() {
    sessionStopwatch.stop();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.discoverSessionEnd,
      params: {
        AnalyticsEvents.paramDurationMs: sessionStopwatch.elapsedMilliseconds,
        AnalyticsEvents.paramSwipesRight: swipesRight,
        AnalyticsEvents.paramSwipesLeft: swipesLeft,
        AnalyticsEvents.paramProfilesViewed: profilesViewed,
      },
    );
  }

  void onSwipeRight(String targetUserId) {
    swipesRight++;
    profilesViewed++;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.discoverSwipeRight,
      params: {
        AnalyticsEvents.paramTargetUserId: targetUserId,
        AnalyticsEvents.paramSource: 'solve_button',
      },
    );
  }

  void onSwipeLeft(String targetUserId) {
    swipesLeft++;
    profilesViewed++;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.discoverSwipeLeft,
      params: {
        AnalyticsEvents.paramTargetUserId: targetUserId,
      },
    );
  }

  void onCardsEmpty() {
    if (!emptyLogged) {
      emptyLogged = true;
      AnalyticsManager.instance.logEvent(AnalyticsEvents.discoverCardsEmpty);
    }
  }

  void listenLocationRecovery() {
    ref.listenManual(locationProvider, (prev, next) {
      if (prev?.error != null && next.error == null && next.lat != null && !next.isLoading) {
        final discover = ref.read(discoverProvider).valueOrNull;
        if (discover == null || !discover.initialized) {
          ref.read(discoverProvider.notifier).loadCards();
        }
      }
    });
  }

  Future<void> initLocationAndDiscover() async {
    final locationState = ref.read(locationProvider);
    final discoverState = ref.read(discoverProvider).valueOrNull;

    if (locationState.lat != null) {
      final isAlreadyLoading = ref.read(discoverProvider) is AsyncLoading;
      if (!isAlreadyLoading && (discoverState == null || !discoverState.initialized)) {
        ref.read(discoverProvider.notifier).loadCards();
      }
      ref.read(locationProvider.notifier).getCurrentLocation();
    } else {
      await ref.read(locationProvider.notifier).getCurrentLocation();
      final isAlreadyLoading = ref.read(discoverProvider) is AsyncLoading;
      final updatedState = ref.read(discoverProvider).valueOrNull;
      if (!isAlreadyLoading && (updatedState == null || !updatedState.initialized)) {
        ref.read(discoverProvider.notifier).loadCards();
      }
    }
  }
}
