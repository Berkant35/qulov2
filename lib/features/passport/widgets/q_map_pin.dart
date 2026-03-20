import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class QMapPin extends StatelessWidget {
  const QMapPin({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.4,
      child: CustomPaint(
        painter: _QMapPinPainter(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.35),
            child: Text(
              'Q',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QMapPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final circleRadius = w * 0.42;
    final centerX = w / 2;
    final centerY = h * 0.38;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final shadowPath = _buildPinPath(centerX, centerY + 3, circleRadius, h);
    canvas.drawPath(shadowPath, shadowPaint);

    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.primary, AppColors.primaryDark],
    );

    final rect = Rect.fromLTWH(0, 0, w, h);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final pinPath = _buildPinPath(centerX, centerY, circleRadius, h);
    canvas.drawPath(pinPath, gradientPaint);

    // White circle highlight (inner)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(centerX - circleRadius * 0.15, centerY - circleRadius * 0.15),
      circleRadius * 0.25,
      highlightPaint,
    );
  }

  Path _buildPinPath(double cx, double cy, double r, double totalHeight) {
    final path = Path();
    final tipY = totalHeight * 0.95;

    // Start from the bottom tip
    path.moveTo(cx, tipY);

    // Left curve from tip to top-left of circle
    path.cubicTo(
      cx - r * 0.4, cy + r * 1.2, // control point 1
      cx - r, cy + r * 0.5,       // control point 2
      cx - r, cy,                  // end: left of circle
    );

    // Top arc (full semicircle over the top)
    path.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi,    // start at left (180°)
      math.pi,    // sweep to right (180°)
    );

    // Right curve from top-right of circle back to tip
    path.cubicTo(
      cx + r, cy + r * 0.5,       // control point 1
      cx + r * 0.4, cy + r * 1.2, // control point 2
      cx, tipY,                    // end: back at tip
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
