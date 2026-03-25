import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class AppLoadingWidget extends StatefulWidget {
  final double size;
  final bool showGlow;

  const AppLoadingWidget({
    super.key,
    this.size = 48,
    this.showGlow = false,
  });

  const AppLoadingWidget.small({super.key})
      : size = 24,
        showGlow = false;

  const AppLoadingWidget.large({super.key})
      : size = 48,
        showGlow = true;

  @override
  State<AppLoadingWidget> createState() => _AppLoadingWidgetState();
}

class _AppLoadingWidgetState extends State<AppLoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  AnimationController? _glowController;
  late _QLogoPainter _painter;
  bool _painterInitialized = false;

  @override
  void initState() {
    super.initState();
    _painter = _QLogoPainter(color: AppColors.primary);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    if (widget.showGlow) {
      _glowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_painterInitialized) {
      _painter = _QLogoPainter(color: context.appColors.primary);
      _painterInitialized = true;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final customPaint = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _painter,
    );

    if (!widget.showGlow) {
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: child,
          );
        },
        child: customPaint,
      );
    }

    final maxGlowSize = widget.size * 1.7;

    return SizedBox(
      width: maxGlowSize,
      height: maxGlowSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _glowController!]),
        builder: (context, child) {
          final glow = _glowController!.value;
          final glowSize = widget.size * (1.4 + glow * 0.3);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Ambient glow
              Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.appColors.primary.withValues(alpha: 0.20 + glow * 0.10),
                      context.appColors.primary.withValues(alpha: 0.05),
                      context.appColors.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Rotating Q logo
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: child,
              ),
            ],
          );
        },
        child: customPaint,
      ),
    );
  }
}

class _QLogoPainter extends CustomPainter {
  final Color color;
  final Paint _strokePaint;
  final Paint _fillPaint;

  _QLogoPainter({required this.color})
      : _strokePaint = (Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round),
        _fillPaint = (Paint()
          ..color = color
          ..style = PaintingStyle.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final strokeWidth = size.width * 0.08;

    _strokePaint.strokeWidth = strokeWidth;

    // Main circle arc — open arc with gap for arrow tip
    const startAngle = math.pi * 0.35;
    const sweepAngle = math.pi * 1.65;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      _strokePaint,
    );

    // Arrow head — sleek chevron at arc end
    final arrowAngle = startAngle + sweepAngle;
    // Tangent direction (where the arc is heading)
    final tangent = arrowAngle + math.pi / 2;
    // Tip sits slightly ahead of arc end along the tangent
    final tipOffset = strokeWidth * 0.3;
    final tip = Offset(
      center.dx + math.cos(arrowAngle) * radius + math.cos(tangent) * tipOffset,
      center.dy + math.sin(arrowAngle) * radius + math.sin(tangent) * tipOffset,
    );

    final arrowLen = strokeWidth * 2.2;
    final arrowHalf = strokeWidth * 0.9;
    // Two wing points — swept back from tip
    final backAngle = tangent + math.pi; // opposite of travel direction
    final wing1 = Offset(
      tip.dx + math.cos(backAngle + 0.45) * arrowLen + math.cos(arrowAngle) * arrowHalf,
      tip.dy + math.sin(backAngle + 0.45) * arrowLen + math.sin(arrowAngle) * arrowHalf,
    );
    final wing2 = Offset(
      tip.dx + math.cos(backAngle - 0.45) * arrowLen - math.cos(arrowAngle) * arrowHalf,
      tip.dy + math.sin(backAngle - 0.45) * arrowLen - math.sin(arrowAngle) * arrowHalf,
    );

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(wing1.dx, wing1.dy)
      ..lineTo(wing2.dx, wing2.dy)
      ..close();

    canvas.drawPath(arrowPath, _fillPaint);
  }

  @override
  bool shouldRepaint(_QLogoPainter old) => old.color != color;
}
