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
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final shadowPath = _buildPinPath(centerX, centerY + 2, circleRadius, h);
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

    // Arc for the circle (top portion)
    final startAngle = math.pi * 0.15;
    final sweepAngle = math.pi * (2 - 0.3);

    path.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
    );

    // Lines to the tip (bottom point)
    path.lineTo(cx, tipY);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
