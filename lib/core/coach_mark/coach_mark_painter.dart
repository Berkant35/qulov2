import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';

class CoachMarkPainter extends CustomPainter {
  CoachMarkPainter({
    required this.holeRect,
    required this.barrierColor,
    required this.shape,
    this.radius = 12,
    this.padding = 6,
  });

  final Rect? holeRect;
  final Color barrierColor;
  final CoachMarkShape shape;
  final double radius;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Path()..addRect(Offset.zero & size);
    final paint = Paint()..color = barrierColor;
    final rect = holeRect;
    if (rect == null) {
      canvas.drawPath(bg, paint);
      return;
    }
    final inflated = rect.inflate(padding);
    final hole = Path();
    if (shape == CoachMarkShape.circle) {
      hole.addOval(inflated);
    } else {
      hole.addRRect(RRect.fromRectAndRadius(inflated, Radius.circular(radius)));
    }
    canvas.drawPath(Path.combine(PathOperation.difference, bg, hole), paint);
  }

  @override
  bool shouldRepaint(CoachMarkPainter old) =>
      old.holeRect != holeRect ||
      old.barrierColor != barrierColor ||
      old.shape != shape;
}
