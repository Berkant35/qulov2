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
  late final AnimationController glitchController;
  late final AnimationController glowController;
  late final AnimationController fadeOutController;

  // ─── Animations ───
  late final Animation<double> glitchAnimation;
  late final Animation<double> glowAnimation;
  late final Animation<double> fadeOutAnimation;

  final Stopwatch _splashStopwatch = Stopwatch()..start();
  bool _authCheckDone = false;
  bool _animationDone = false;

  void initMixin() {
    _setupControllers();
    _setupAnimations();
    _startAnimation();
    _startAuthCheckInParallel();
  }

  void _setupControllers() {
    glitchController = AnimationController(
      vsync: this,
      duration: AppDurations.splashGlitch,
    );

    glowController = AnimationController(
      vsync: this,
      duration: AppDurations.splashGlowSettle,
    );

    fadeOutController = AnimationController(
      vsync: this,
      duration: AppDurations.splashFadeOut,
    );
  }

  void _setupAnimations() {
    glitchAnimation = CurvedAnimation(
      parent: glitchController,
      curve: Curves.easeOutCubic,
    );

    glowAnimation = CurvedAnimation(
      parent: glowController,
      curve: Curves.easeOut,
    );

    fadeOutAnimation = CurvedAnimation(
      parent: fadeOutController,
      curve: Curves.easeIn,
    );
  }

  void disposeMixin() {
    glitchController.dispose();
    glowController.dispose();
    fadeOutController.dispose();
  }

  Future<void> _startAnimation() async {
    // Phase 1: Glitch chaos (1000ms)
    await glitchController.forward().orCancel.catchError((_) {});
    if (!mounted) return;

    // Phase 2: Glow settle (500ms)
    await glowController.forward().orCancel.catchError((_) {});
    if (!mounted) return;

    // Ensure minimum display time (3000ms total)
    final elapsed = _splashStopwatch.elapsedMilliseconds;
    final remaining = AppDurations.splashMinDisplay.inMilliseconds - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }
    if (!mounted) return;

    _animationDone = true;
    _tryProceed();
  }

  Future<void> _startAuthCheckInParallel() async {
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

    _authCheckDone = true;
    _tryProceed();
  }

  void _tryProceed() {
    if (!_animationDone || !_authCheckDone || !mounted) return;
    ref.read(authProvider.notifier).checkAuth();
  }

  Future<void> _showOptionalUpdateThenContinue() async {
    final notifier = ref.read(appConfigProvider.notifier);
    final isDismissed = await notifier.isOptionalUpdateDismissed();

    if (isDismissed) {
      _authCheckDone = true;
      _tryProceed();
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

    _authCheckDone = true;
    _tryProceed();
  }
}
