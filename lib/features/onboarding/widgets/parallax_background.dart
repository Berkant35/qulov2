import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class ParallaxBackground extends StatelessWidget {
  final double scrollOffset;
  final Animation<double> floatingAnimation;

  const ParallaxBackground({
    super.key,
    required this.scrollOffset,
    required this.floatingAnimation,
  });

  static const _powerIcons = [
    _FloatingElement(
      assetPath: QIcons.icOracle,
      relX: 0.08,
      relY: 0.12,
      size: 22,
      speed: 1.2,
      phase: 0.0,
      baseOpacity: 0.10,
      parallaxFactor: 0.6,
      isPowerIcon: true,
    ),
    _FloatingElement(
      assetPath: QIcons.icSplit,
      relX: 0.85,
      relY: 0.18,
      size: 20,
      speed: 0.9,
      phase: 1.0,
      baseOpacity: 0.08,
      parallaxFactor: 0.6,
      isPowerIcon: true,
    ),
    _FloatingElement(
      assetPath: QIcons.icSkipForward,
      relX: 0.15,
      relY: 0.42,
      size: 18,
      speed: 1.4,
      phase: 2.1,
      baseOpacity: 0.12,
      parallaxFactor: 0.6,
      isPowerIcon: true,
    ),
    _FloatingElement(
      assetPath: QIcons.icLightbulb,
      relX: 0.92,
      relY: 0.52,
      size: 24,
      speed: 1.1,
      phase: 3.2,
      baseOpacity: 0.10,
      parallaxFactor: 0.6,
      isPowerIcon: true,
    ),
    _FloatingElement(
      assetPath: QIcons.icClock,
      relX: 0.05,
      relY: 0.72,
      size: 16,
      speed: 1.3,
      phase: 4.0,
      baseOpacity: 0.08,
      parallaxFactor: 0.6,
      isPowerIcon: true,
    ),
    _FloatingElement(
      assetPath: QIcons.icFastForward,
      relX: 0.88,
      relY: 0.82,
      size: 20,
      speed: 1.0,
      phase: 5.5,
      baseOpacity: 0.12,
      parallaxFactor: 0.6,
      isPowerIcon: true,
    ),
  ];

  static const _diamonds = [
    _FloatingElement(
      assetPath: AppAssets.greenDiamond,
      relX: 0.78,
      relY: 0.08,
      size: 28,
      speed: 0.7,
      phase: 0.5,
      baseOpacity: 0.12,
      parallaxFactor: 0.3,
      isPowerIcon: false,
    ),
    _FloatingElement(
      assetPath: AppAssets.purpleDiamond,
      relX: 0.12,
      relY: 0.30,
      size: 24,
      speed: 0.8,
      phase: 1.8,
      baseOpacity: 0.10,
      parallaxFactor: 0.3,
      isPowerIcon: false,
    ),
    _FloatingElement(
      assetPath: AppAssets.greenDiamond,
      relX: 0.90,
      relY: 0.60,
      size: 22,
      speed: 0.6,
      phase: 3.0,
      baseOpacity: 0.14,
      parallaxFactor: 0.3,
      isPowerIcon: false,
    ),
    _FloatingElement(
      assetPath: AppAssets.purpleDiamond,
      relX: 0.06,
      relY: 0.88,
      size: 26,
      speed: 0.9,
      phase: 4.2,
      baseOpacity: 0.18,
      parallaxFactor: 0.3,
      isPowerIcon: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      animation: floatingAnimation,
      builder: (context, _) {
        final time = floatingAnimation.value;
        final currentPage = scrollOffset.round().clamp(0, 4);

        return Stack(
          children: [
            for (final element in _powerIcons)
              _FloatingElementView(
                element: element,
                time: time,
                currentPage: currentPage,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                scrollOffset: scrollOffset,
              ),
            for (final element in _diamonds)
              _FloatingElementView(
                element: element,
                time: time,
                currentPage: currentPage,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                scrollOffset: scrollOffset,
              ),
          ],
        );
      },
    );
  }

}

/// Tek bir yuzen arka plan ogesi — parallax kaydirma + sinuzoidal salinim.
class _FloatingElementView extends StatelessWidget {
  const _FloatingElementView({
    required this.element,
    required this.time,
    required this.currentPage,
    required this.screenWidth,
    required this.screenHeight,
    required this.scrollOffset,
  });

  final _FloatingElement element;
  final double time;
  final int currentPage;
  final double screenWidth;
  final double screenHeight;
  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final parallaxX = -scrollOffset * screenWidth * element.parallaxFactor;
    final floatX = sin(time * element.speed + element.phase) * 6;
    final floatY = cos(time * element.speed * 0.7 + element.phase) * 8;

    // Page-based opacity boost
    double opacityBoost = 0;
    if (element.isPowerIcon && (currentPage == 2 || currentPage == 3)) {
      opacityBoost = 0.12;
    } else if (!element.isPowerIcon && (currentPage == 3 || currentPage == 4)) {
      opacityBoost = 0.15;
    }

    final opacity = (element.baseOpacity + opacityBoost).clamp(0.0, 0.4);

    final left = element.relX * screenWidth + parallaxX + floatX;
    final top = element.relY * screenHeight + floatY;

    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: element.isPowerIcon
            ? SvgPicture.asset(
                element.assetPath,
                width: element.size,
                height: element.size,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              )
            : SvgPicture.asset(
                element.assetPath,
                width: element.size,
                height: element.size,
              ),
      ),
    );
  }
}

class _FloatingElement {
  final String assetPath;
  final double relX;
  final double relY;
  final double size;
  final double speed;
  final double phase;
  final double baseOpacity;
  final double parallaxFactor;
  final bool isPowerIcon;

  const _FloatingElement({
    required this.assetPath,
    required this.relX,
    required this.relY,
    required this.size,
    required this.speed,
    required this.phase,
    required this.baseOpacity,
    required this.parallaxFactor,
    required this.isPowerIcon,
  });
}
