import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/features/discover/coach/discover_coach_marks.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

mixin DiscoverScreenMixin on ConsumerState<DiscoverScreen> {
  final Stopwatch sessionStopwatch = Stopwatch()..start();
  int swipesRight = 0;
  int swipesLeft = 0;
  int profilesViewed = 0;
  bool emptyLogged = false;
  bool _coachTried = false;

  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.discoverSessionStart);
    Future.microtask(() => initLocationAndDiscover());
    listenLocationRecovery();
  }

  void disposeMixin() {
    CoachMarkService.instance.forceClose();
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

  /// First discover visit shows the "how Qulo works" intro unconditionally
  /// (even on empty discover / before the user has questions). Once the intro
  /// is seen, a later visit with cards shows the anchored solve/action steps.
  void maybeStartDiscoverCoach({required bool hasCards}) {
    if (_coachTried) return;
    _coachTried = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final service = CoachMarkService.instance;
      final introSeen = await service.isSeen('discover_intro');
      if (!mounted) return;
      if (!introSeen) {
        await service.maybeStartTour(
          context,
          tourId: 'discover_intro',
          steps: buildDiscoverIntroSteps(),
        );
        return; // anchored steps come on a later visit, once cards exist
      }
      if (hasCards) {
        await service.maybeStartTour(
          context,
          tourId: 'discover_steps',
          steps: buildDiscoverActionSteps(),
        );
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
      // Skip loadCards when location failed — backend throws PROFILE_INCOMPLETE without lat/lng.
      final updatedLocation = ref.read(locationProvider);
      if (updatedLocation.lat == null) return;

      final isAlreadyLoading = ref.read(discoverProvider) is AsyncLoading;
      final updatedState = ref.read(discoverProvider).valueOrNull;
      if (!isAlreadyLoading && (updatedState == null || !updatedState.initialized)) {
        ref.read(discoverProvider.notifier).loadCards();
      }
    }
  }
}
