import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/splash/mixins/splash_screen_mixin.dart';
import 'package:qulo_v2/features/splash/widgets/question_rain.dart';
import 'package:qulo_v2/features/splash/widgets/splash_flow_story.dart';
import 'package:qulo_v2/features/splash/widgets/splash_logo.dart';
import 'package:qulo_v2/features/splash/widgets/splash_text.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

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
      body: Stack(
        children: [
          // Subtle radial gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    context.appColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Question mark rain — runs continuously until page transition
          Positioned.fill(
            child: QuestionRain(fadeIn: rainFadeIn),
          ),
          // Logo + Text centered
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SplashLogo(
                  fadeIn: logoFade,
                  scale: logoScale,
                  glowPulse: glowPulse,
                  shimmer: shimmerAnimation,
                  ringExpand: ringExpandAnimation,
                ),
                const SizedBox(height: AppSpacing.xl),
                SplashText(animation: textAnimation),
              ],
            ),
          ),
          // Flow story timeline at the bottom: ? → ✓ → ❤️
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxxl,
            child: Center(
              child: SplashFlowStory(animation: flowStoryAnimation),
            ),
          ),
        ],
      ),
    );
  }
}
