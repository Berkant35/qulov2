import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class SplashLogo extends StatelessWidget {
  final Animation<double> fadeIn;
  final Animation<double> scale;
  final Animation<double> glowPulse;
  final Animation<double> shimmer;
  final Animation<double> ringExpand;

  const SplashLogo({
    super.key,
    required this.fadeIn,
    required this.scale,
    required this.glowPulse,
    required this.shimmer,
    required this.ringExpand,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.appColors.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([fadeIn, glowPulse, shimmer, ringExpand]),
      builder: (context, child) {
        final glowAlpha = 0.2 + 0.25 * glowPulse.value;
        final glowRadius = 50.0 + 30.0 * glowPulse.value;

        return FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(
            scale: scale,
            child: SizedBox(
              width: AppSizes.logoLg * 2.2,
              height: AppSizes.logoLg * 2.2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Expanding ring
                  if (ringExpand.value > 0)
                    _ExpandingRing(
                      progress: ringExpand.value,
                      color: primary,
                    ),
                  // Neon glow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: glowAlpha),
                          blurRadius: glowRadius,
                          spreadRadius: 15 + 10 * glowPulse.value,
                        ),
                        BoxShadow(
                          color: primary.withValues(alpha: glowAlpha * 0.5),
                          blurRadius: glowRadius * 1.8,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  // Shimmer sweep
                  if (shimmer.value > 0)
                    ClipOval(
                      child: SizedBox(
                        width: AppSizes.logoLg,
                        height: AppSizes.logoLg,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            final sweep = shimmer.value * 2.0 - 0.5;
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                              stops: [
                                (sweep - 0.2).clamp(0.0, 1.0),
                                sweep.clamp(0.0, 1.0),
                                (sweep + 0.2).clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: SvgPicture.asset(
        AppAssets.logoSvg,
        width: AppSizes.logoLg,
        height: AppSizes.logoLg,
        colorFilter: ColorFilter.mode(
          context.appColors.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _ExpandingRing extends StatelessWidget {
  final double progress;
  final Color color;

  const _ExpandingRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.logoLg * (1.0 + progress * 0.8);
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 2.0 - progress * 1.5,
        ),
      ),
    );
  }
}
