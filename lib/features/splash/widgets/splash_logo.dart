import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/splash/widgets/glitch_painter.dart';

class SplashLogo extends StatefulWidget {
  /// 0→1: glitch chaos→stable
  final Animation<double> glitch;

  /// 0→1: glow pulse settle
  final Animation<double> glow;

  const SplashLogo({
    super.key,
    required this.glitch,
    required this.glow,
  });

  @override
  State<SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<SplashLogo> {
  ui.Image? _rasterImage;
  static const _sliceCount = 12;
  final _seeds = GlitchSliceSeed.generate(_sliceCount);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rasterImage == null) {
      _rasterizeSvg();
    }
  }

  Future<void> _rasterizeSvg() async {
    final pictureInfo = await vg.loadPicture(
      SvgAssetLoader(AppAssets.logoSvg),
      null,
    );

    // Render at 2x for sharpness
    const targetSize = AppSizes.logoLg * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = targetSize / pictureInfo.size.width;
    canvas.scale(scale, scale);
    canvas.drawPicture(pictureInfo.picture);
    pictureInfo.picture.dispose();

    final image = await recorder
        .endRecording()
        .toImage(targetSize.toInt(), targetSize.toInt());

    if (mounted) {
      setState(() => _rasterImage = image);
    }
  }

  @override
  void dispose() {
    _rasterImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.appColors.primary;

    if (_rasterImage == null) {
      return const SizedBox(
        width: AppSizes.logoLg,
        height: AppSizes.logoLg,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([widget.glitch, widget.glow]),
      builder: (context, _) {
        final glowValue = widget.glow.value;
        // Glow settle: 0→0.4→0.2
        final glowAlpha = glowValue < 0.5
            ? glowValue * 0.8 // 0→0.4
            : 0.4 - (glowValue - 0.5) * 0.4; // 0.4→0.2
        final glowRadius = 40.0 + 20.0 * glowValue;

        return SizedBox(
          width: AppSizes.logoLg,
          height: AppSizes.logoLg,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Neon glow (visible after glitch stabilizes)
              if (widget.glitch.value > 0.8)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: glowAlpha),
                        blurRadius: glowRadius,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: primary.withValues(alpha: glowAlpha * 0.5),
                        blurRadius: glowRadius * 1.6,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              // Glitch painter
              RepaintBoundary(
                child: CustomPaint(
                  size: const Size(AppSizes.logoLg, AppSizes.logoLg),
                  painter: GlitchPainter(
                    image: _rasterImage!,
                    progress: widget.glitch.value,
                    seeds: _seeds,
                    tintColor: primary,
                    sliceCount: _sliceCount,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
