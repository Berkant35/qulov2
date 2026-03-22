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
  late final AnimationController logoController;
  late final AnimationController textController;
  late final Animation<double> logoFade;
  late final Animation<double> logoScale;
  late final Animation<double> textFade;

  final Stopwatch _splashStopwatch = Stopwatch()..start();

  void initMixin() {
    logoController = AnimationController(
      vsync: this,
      duration: AppDurations.splashLogo,
    );

    textController = AnimationController(
      vsync: this,
      duration: AppDurations.splashText,
    );

    logoFade = CurvedAnimation(
      parent: logoController,
      curve: Curves.easeIn,
    );

    logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: logoController, curve: Curves.easeOutBack),
    );

    textFade = CurvedAnimation(
      parent: textController,
      curve: Curves.easeIn,
    );

    _startAnimation();
  }

  void disposeMixin() {
    logoController.dispose();
    textController.dispose();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(AppDurations.splashInitDelay);
    if (!mounted) return;

    logoController.forward();

    await Future.delayed(AppDurations.splashTextDelay);
    if (!mounted) return;

    textController.forward();

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
