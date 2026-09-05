import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/splash/mixins/splash_screen_mixin.dart';
import 'package:qulo_v2/features/splash/widgets/splash_logo.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin, SplashScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: FadeTransition(
        opacity: ReverseAnimation(fadeOutAnimation),
        child: Stack(
          children: [
            // Deep gradient background
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.splashGradient,
                ),
              ),
            ),
            // Radial spotlight overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6,
                    colors: [
                      AppColors.splashSpotlight.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Glitch logo centered
            Center(
              child: SplashLogo(
                glitch: glitchAnimation,
                glow: glowAnimation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
