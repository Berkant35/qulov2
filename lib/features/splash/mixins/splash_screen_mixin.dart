import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/splash/splash_screen.dart';

mixin SplashScreenMixin on ConsumerState<SplashScreen>
    implements TickerProvider {
  // ─── Animation Controllers ───
  late final AnimationController rainFadeInController;
  late final AnimationController logoController;
  late final AnimationController glowPulseController;
  late final AnimationController shimmerController;
  late final AnimationController ringExpandController;
  late final AnimationController textController;
  late final AnimationController flowStoryController;

  // ─── Animations ───
  late final Animation<double> rainFadeIn;
  late final Animation<double> logoFade;
  late final Animation<double> logoScale;
  late final Animation<double> glowPulse;
  late final Animation<double> shimmerAnimation;
  late final Animation<double> ringExpandAnimation;
  late final Animation<double> textAnimation;
  late final Animation<double> flowStoryAnimation;

  final Stopwatch _splashStopwatch = Stopwatch()..start();

  void initMixin() {
    _setupControllers();
    _setupAnimations();
    _startAnimation();
  }

  void _setupControllers() {
    rainFadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    logoController = AnimationController(
      vsync: this,
      duration: AppDurations.splashLogo,
    );

    glowPulseController = AnimationController(
      vsync: this,
      duration: AppDurations.splashGlowPulse,
    );

    shimmerController = AnimationController(
      vsync: this,
      duration: AppDurations.splashShimmer,
    );

    ringExpandController = AnimationController(
      vsync: this,
      duration: AppDurations.splashRingExpand,
    );

    textController = AnimationController(
      vsync: this,
      duration: AppDurations.splashStaggeredText,
    );

    flowStoryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  void _setupAnimations() {
    rainFadeIn = CurvedAnimation(
      parent: rainFadeInController,
      curve: Curves.easeIn,
    );

    logoFade = CurvedAnimation(
      parent: logoController,
      curve: Curves.easeIn,
    );

    logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: logoController, curve: Curves.elasticOut),
    );

    glowPulse = CurvedAnimation(
      parent: glowPulseController,
      curve: Curves.easeInOut,
    );

    shimmerAnimation = CurvedAnimation(
      parent: shimmerController,
      curve: Curves.easeInOut,
    );

    ringExpandAnimation = CurvedAnimation(
      parent: ringExpandController,
      curve: Curves.easeOut,
    );

    textAnimation = CurvedAnimation(
      parent: textController,
      curve: Curves.easeOut,
    );

    flowStoryAnimation = CurvedAnimation(
      parent: flowStoryController,
      curve: Curves.easeOut,
    );
  }

  void disposeMixin() {
    rainFadeInController.dispose();
    logoController.dispose();
    glowPulseController.dispose();
    shimmerController.dispose();
    ringExpandController.dispose();
    textController.dispose();
    flowStoryController.dispose();
  }

  Future<void> _startAnimation() async {
    // Phase 1: Question rain fades in
    await Future.delayed(AppDurations.splashInitDelay);
    if (!mounted) return;
    rainFadeInController.forward();

    // Phase 2: Logo enters with elastic bounce (400ms after rain starts)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    logoController.forward();
    ringExpandController.forward();

    // Phase 3: Glow pulse starts looping after logo lands
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    glowPulseController.repeat(reverse: true);

    // Phase 4: Shimmer sweep across logo
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    shimmerController.forward();

    // Phase 5: Staggered text
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    textController.forward();

    // Phase 6: Flow story timeline (? → ✓ → ❤️)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    flowStoryController.forward();

    // Hold before auth check
    await Future.delayed(AppDurations.splashHold);
    if (!mounted) return;

    _checkVersionAndAuth();
  }

  Future<void> _checkVersionAndAuth() async {
    _splashStopwatch.stop();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.appSplashDuration,
      params: {
        AnalyticsEvents.paramDurationMs: _splashStopwatch.elapsedMilliseconds,
      },
    );

    final status = await ref.read(appConfigProvider.notifier).checkVersion();
    if (!mounted) return;

    await ref.read(economyConfigProvider.notifier).fetch();
    if (!mounted) return;

    switch (status) {
      case UpdateStatus.maintenance:
        AnalyticsManager.instance
            .logEvent(AnalyticsEvents.appMaintenanceShown);
        ref.read(navigationServiceProvider).go(RouteNames.maintenance);
        return;
      case UpdateStatus.forceUpdate:
        AnalyticsManager.instance
            .logEvent(AnalyticsEvents.appForceUpdateShown);
        ref.read(navigationServiceProvider).go(RouteNames.forceUpdate);
        return;
      case UpdateStatus.optionalUpdate:
        AnalyticsManager.instance
            .logEvent(AnalyticsEvents.appOptionalUpdateShown);
        await _showOptionalUpdateThenContinue();
        return;
      case UpdateStatus.none:
        break;
    }

    _continueToAuth();
  }

  Future<void> _showOptionalUpdateThenContinue() async {
    final notifier = ref.read(appConfigProvider.notifier);
    final isDismissed = await notifier.isOptionalUpdateDismissed();

    if (isDismissed) {
      _continueToAuth();
      return;
    }

    if (!mounted) return;

    final config = ref.read(appConfigProvider).config;
    final result =
        await ref.read(navigationServiceProvider).showAppDialog<bool>(
              ConfirmDialog(
                name: 'optional_update',
                title: context.tr('update_available_title'),
                message: context.tr('update_available_message'),
                confirmText: context.tr('update_button'),
                cancelText: context.tr('update_later'),
              ),
            );

    if (result == true && config != null && config.storeUrl.isNotEmpty) {
      ref.read(urlLauncherManagerProvider).launch(config.storeUrl);
    } else {
      await notifier.dismissOptionalUpdate();
    }

    _continueToAuth();
  }

  void _continueToAuth() {
    ref.read(authProvider.notifier).checkAuth();
  }
}
