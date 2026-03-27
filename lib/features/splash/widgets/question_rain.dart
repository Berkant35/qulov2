import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

/// Continuously falling "?" characters that rain until the widget is disposed.
/// Uses a repeating AnimationController for an infinite loop.
class QuestionRain extends StatefulWidget {
  /// Master opacity — allows parent to fade the rain in.
  final Animation<double>? fadeIn;

  const QuestionRain({super.key, this.fadeIn});

  @override
  State<QuestionRain> createState() => _QuestionRainState();
}

class _QuestionRainState extends State<QuestionRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.appColors.primary;

    Widget rain = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.sizeOf(context),
          painter: _QuestionRainPainter(
            tick: _controller.value,
            color: primary,
          ),
        );
      },
    );

    if (widget.fadeIn != null) {
      rain = FadeTransition(opacity: widget.fadeIn!, child: rain);
    }

    return rain;
  }
}

// ─── Painter ───────────────────────────────────────────────────────────────

class _QuestionRainPainter extends CustomPainter {
  final double tick;
  final Color color;

  static const _dropCount = 40;
  static final List<_Drop> _drops = _generateDrops();

  _QuestionRainPainter({required this.tick, required this.color});

  static List<_Drop> _generateDrops() {
    final rng = Random(7);
    return List.generate(_dropCount, (_) {
      return _Drop(
        x: rng.nextDouble(),
        startY: -rng.nextDouble() * 0.4, // start above viewport
        speed: 0.25 + rng.nextDouble() * 0.45,
        size: 10.0 + rng.nextDouble() * 18.0,
        opacity: 0.08 + rng.nextDouble() * 0.22,
        drift: (rng.nextDouble() - 0.5) * 0.03,
        phase: rng.nextDouble(), // offset so they don't all start together
        rotationSpeed: (rng.nextDouble() - 0.5) * 0.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _drops) {
      // Continuous fall: each drop loops independently via its phase offset
      final t = (tick + d.phase) % 1.0;
      final fallProgress = t * (1.0 + 0.4) * d.speed;

      // y: starts above screen (-0.2) → falls past bottom (1.2), then wraps
      final rawY = d.startY + fallProgress * 2.5;
      final y = ((rawY % 1.4) - 0.2) * size.height;

      final x = (d.x + d.drift * sin(tick * pi * 2)) * size.width;
      final rotation = tick * pi * 2 * d.rotationSpeed;

      // Fade out near edges
      final normalizedY = y / size.height;
      final edgeFade = normalizedY < 0.05
          ? (normalizedY / 0.05).clamp(0.0, 1.0)
          : normalizedY > 0.9
              ? ((1.0 - normalizedY) / 0.1).clamp(0.0, 1.0)
              : 1.0;

      final alpha = d.opacity * edgeFade;
      if (alpha < 0.01) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Glow behind the "?"
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset.zero, d.size * 0.6, glowPaint);

      // Draw "?" character
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: color.withValues(alpha: alpha),
            fontSize: d.size,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_QuestionRainPainter old) => true; // continuous
}

// ─── Data ──────────────────────────────────────────────────────────────────

class _Drop {
  final double x, startY, speed, size, opacity, drift, phase, rotationSpeed;

  const _Drop({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.drift,
    required this.phase,
    required this.rotationSpeed,
  });
}
