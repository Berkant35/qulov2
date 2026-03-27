import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders a [ui.Image] with horizontal-slice displacement and RGB channel
/// separation.  [progress] drives the animation:
///   0.0 = full chaos   →   1.0 = fully stabilized
class GlitchPainter extends CustomPainter {
  final ui.Image image;
  final double progress;
  final int sliceCount;
  final Color tintColor;

  /// Pre-computed per-slice random seeds — created once per widget lifecycle
  /// and passed in so the painter stays deterministic across repaints.
  final List<GlitchSliceSeed> seeds;

  GlitchPainter({
    required this.image,
    required this.progress,
    required this.seeds,
    required this.tintColor,
    this.sliceCount = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final sliceH = imgH / sliceCount;

    // chaos = 1.0 at start, 0.0 when stabilized
    final chaos = (1.0 - progress).clamp(0.0, 1.0);

    // Flicker: random opacity bursts during chaos phase
    final flickerAlpha = chaos > 0.05
        ? (0.3 + 0.7 * (0.5 + 0.5 * sin(progress * pi * 20 + seeds[0].phase)))
        : 1.0;

    // Scale image to fit the target size
    final scaleX = size.width / imgW;
    final scaleY = size.height / imgH;

    for (var i = 0; i < sliceCount; i++) {
      final seed = seeds[i];
      final srcTop = sliceH * i;
      final srcRect = Rect.fromLTWH(0, srcTop, imgW, sliceH);

      final dstTop = sliceH * scaleY * i;
      final dstH = sliceH * scaleY;

      // X displacement decays with progress (chaos → stable)
      final maxDisplacement = seed.displacement * 40.0;
      final dx = maxDisplacement * chaos * sin(progress * pi * 8 + seed.phase);

      // RGB channel offsets
      final rgbOffset = chaos * seed.rgbShift * 6.0;

      // Draw R channel (shifted left)
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, dstTop, size.width, dstH));

      // Red channel
      canvas.drawImageRect(
        image,
        srcRect,
        Rect.fromLTWH(dx - rgbOffset, dstTop, imgW * scaleX, dstH),
        Paint()
          ..colorFilter = const ColorFilter.mode(Colors.red, BlendMode.modulate)
          ..color = Colors.white.withValues(alpha: flickerAlpha * 0.5),
      );

      // Green channel (center)
      canvas.drawImageRect(
        image,
        srcRect,
        Rect.fromLTWH(dx, dstTop, imgW * scaleX, dstH),
        Paint()
          ..colorFilter =
              const ColorFilter.mode(Colors.green, BlendMode.modulate)
          ..color = Colors.white.withValues(alpha: flickerAlpha * 0.5),
      );

      // Blue channel (shifted right)
      canvas.drawImageRect(
        image,
        srcRect,
        Rect.fromLTWH(dx + rgbOffset, dstTop, imgW * scaleX, dstH),
        Paint()
          ..colorFilter =
              const ColorFilter.mode(Colors.blue, BlendMode.modulate)
          ..color = Colors.white.withValues(alpha: flickerAlpha * 0.5),
      );

      canvas.restore();
    }

    // Scan lines overlay during chaos
    if (chaos > 0.05) {
      final scanPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08 * chaos)
        ..strokeWidth = 1;
      for (var y = 0.0; y < size.height; y += 3) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
      }
    }

    // Normal composited image fades in as chaos fades out
    // This is the "clean" version that replaces the RGB split
    if (progress > 0.4) {
      final cleanAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, imgW, imgH),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..colorFilter = ColorFilter.mode(tintColor, BlendMode.srcIn)
          ..color = Colors.white.withValues(alpha: cleanAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(GlitchPainter old) =>
      old.progress != progress || old.image != image;
}

/// Random seed data for one horizontal slice.
class GlitchSliceSeed {
  final double displacement; // 0–1
  final double rgbShift; // 0–1
  final double phase; // 0–2π

  const GlitchSliceSeed({
    required this.displacement,
    required this.rgbShift,
    required this.phase,
  });

  static List<GlitchSliceSeed> generate(int count, [int seed = 42]) {
    final rng = Random(seed);
    return List.generate(count, (_) {
      return GlitchSliceSeed(
        displacement: rng.nextDouble(),
        rgbShift: 0.3 + rng.nextDouble() * 0.7,
        phase: rng.nextDouble() * pi * 2,
      );
    });
  }
}
