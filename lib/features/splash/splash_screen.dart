import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: AppDurations.splashLogo,
    );

    _textController = AnimationController(
      vsync: this,
      duration: AppDurations.splashText,
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(AppDurations.splashInitDelay);
    if (!mounted) return;

    _logoController.forward();

    await Future.delayed(AppDurations.splashTextDelay);
    if (!mounted) return;

    _textController.forward();

    await Future.delayed(AppDurations.splashHold);
    if (!mounted) return;

    _checkVersionAndAuth();
  }

  Future<void> _checkVersionAndAuth() async {
    final status = await ref.read(appConfigProvider.notifier).checkVersion();
    if (!mounted) return;

    switch (status) {
      case UpdateStatus.maintenance:
        ref.read(navigationServiceProvider).go(RouteNames.maintenance);
        return;
      case UpdateStatus.forceUpdate:
        ref.read(navigationServiceProvider).go(RouteNames.forceUpdate);
        return;
      case UpdateStatus.optionalUpdate:
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
    final result = await ref.read(navigationServiceProvider).showAppDialog<bool>(
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

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    AppAssets.logoSvg,
                    width: AppSizes.logoLg,
                    height: AppSizes.logoLg,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeTransition(
              opacity: _textFade,
              child: Text(
                'QULO',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
