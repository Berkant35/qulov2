import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

enum DiamondType { purple, green }

class DiamondIcon extends StatefulWidget {
  final DiamondType type;
  final double size;
  final bool showGlow;

  const DiamondIcon({
    super.key,
    required this.type,
    this.size = 32,
    this.showGlow = true,
  });

  const DiamondIcon.purple({super.key, this.size = 32, this.showGlow = true})
      : type = DiamondType.purple;

  const DiamondIcon.green({super.key, this.size = 32, this.showGlow = true})
      : type = DiamondType.green;

  @override
  State<DiamondIcon> createState() => _DiamondIconState();
}

class _DiamondIconState extends State<DiamondIcon>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _smokeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.showGlow) {
      _pulseController.repeat(reverse: true);
      _smokeController.repeat();
    }
  }

  @override
  void didUpdateWidget(DiamondIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGlow && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      _smokeController.repeat();
    } else if (!widget.showGlow && _pulseController.isAnimating) {
      _pulseController.stop();
      _smokeController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  String get _assetPath => widget.type == DiamondType.purple
      ? AppAssets.purpleDiamond
      : AppAssets.greenDiamond;

  Color get _glowColor => widget.type == DiamondType.purple
      ? AppColors.primary
      : context.appColors.secondary;

  Color get _glowColorDark => widget.type == DiamondType.purple
      ? context.appColors.primaryDark
      : context.appColors.secondaryDark;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      _assetPath,
      width: widget.size,
      height: widget.size,
    );

    if (!widget.showGlow) {
      return SizedBox(width: widget.size, height: widget.size, child: svg);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _smokeController]),
        builder: (context, child) {
          final pulse = _pulseController.value;
          final smoke = _smokeController.value;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Layer 1: Ambient glow
              _AmbientGlow(pulse: pulse, size: widget.size, color: _glowColor),
              // Layer 2: Rotating smoke
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _SmokePainter(
                  color: _glowColor,
                  colorDark: _glowColorDark,
                  progress: smoke,
                  pulse: pulse,
                  iconSize: widget.size,
                ),
              ),
              // Layer 3: Core glow
              _CoreGlow(pulse: pulse, size: widget.size, color: _glowColor),
              // Layer 4: Diamond SVG
              child!,
              // Layer 5: Sparkles
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _SparklePainter(
                  progress: smoke,
                  iconSize: widget.size,
                  sparkleColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          );
        },
        child: svg,
      ),
    );
  }
}

/// Layer 1 — elmasin cevresine yayilan yumusak halka.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.pulse,
    required this.size,
    required this.color,
  });

  final double pulse;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glowSize = size * (1.2 + pulse * 0.3);
    return Container(
      width: glowSize,
      height: glowSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.25 + pulse * 0.12),
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Layer 3 — elmasin merkezindeki yogun parlama.
class _CoreGlow extends StatelessWidget {
  const _CoreGlow({
    required this.pulse,
    required this.size,
    required this.color,
  });

  final double pulse;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final coreSize = size * (0.5 + pulse * 0.15);
    return Container(
      width: coreSize,
      height: coreSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4 + pulse * 0.2),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
    );
  }
}

class _SmokePainter extends CustomPainter {
  final Color color;
  final Color colorDark;
  final double progress;
  final double pulse;
  final double iconSize;

  _SmokePainter({
    required this.color,
    required this.colorDark,
    required this.progress,
    required this.pulse,
    required this.iconSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = progress * 2 * math.pi;

    for (int i = 0; i < 5; i++) {
      final blobAngle = angle + (i * 2 * math.pi / 5);
      final orbitDist = iconSize * (0.38 + 0.08 * math.sin(angle * 3 + i * 1.5));
      final blobX = center.dx + math.cos(blobAngle) * orbitDist;
      final blobY = center.dy + math.sin(blobAngle) * orbitDist;

      final depth = math.sin(blobAngle);
      final depthAlpha = 0.15 + (depth + 1) * 0.15;
      final blobScale = 0.7 + (depth + 1) * 0.25;
      final blobRadius = iconSize * 0.22 * blobScale * (0.85 + pulse * 0.15);

      final blobCenter = Offset(blobX, blobY);
      final blobColor = i.isEven ? color : colorDark;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blobColor.withValues(alpha: depthAlpha),
            blobColor.withValues(alpha: depthAlpha * 0.3),
            blobColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
          Rect.fromCircle(center: blobCenter, radius: blobRadius),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, iconSize * 0.08);

      canvas.drawCircle(blobCenter, blobRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) =>
      old.progress != progress || old.pulse != pulse;
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final double iconSize;
  final Color sparkleColor;

  _SparklePainter({required this.progress, required this.iconSize, required this.sparkleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = -progress * 2 * math.pi * 1.5;

    for (int i = 0; i < 3; i++) {
      final sa = angle + (i * 2 * math.pi / 3);
      final dist = iconSize * (0.25 + 0.08 * math.sin(progress * 8 * math.pi + i));
      final sx = center.dx + math.cos(sa) * dist;
      final sy = center.dy + math.sin(sa) * dist;
      final alpha = 0.4 + 0.4 * math.sin(progress * 10 * math.pi + i * 2);

      canvas.drawCircle(
        Offset(sx, sy),
        iconSize * 0.015,
        Paint()
          ..color = sparkleColor.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, iconSize * 0.01),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
