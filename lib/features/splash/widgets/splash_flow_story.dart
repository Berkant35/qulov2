import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Animated timeline at the bottom of splash:  ? → ✓ → ❤️
/// Each step appears sequentially to tell the app story.
class SplashFlowStory extends StatelessWidget {
  /// 0.0 → 1.0 drives the entire 3-step sequence.
  final Animation<double> animation;

  const SplashFlowStory({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;

        // Stagger: step1 0.0-0.30, line1 0.20-0.45, step2 0.35-0.60,
        //          line2 0.50-0.75, step3 0.65-1.0
        final step1 = _interval(t, 0.0, 0.30);
        final line1 = _interval(t, 0.20, 0.45);
        final step2 = _interval(t, 0.35, 0.60);
        final line2 = _interval(t, 0.50, 0.75);
        final step3 = _interval(t, 0.65, 1.0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepIcon(
              icon: '?',
              label: context.tr('splash_flow_ask'),
              progress: step1,
              color: colors.primary,
              textColor: colors.textSecondary,
            ),
            _ConnectorLine(progress: line1, color: colors.primary),
            _StepIcon(
              icon: '✓',
              label: context.tr('splash_flow_answer'),
              progress: step2,
              color: colors.secondary,
              textColor: colors.textSecondary,
            ),
            _ConnectorLine(progress: line2, color: colors.secondary),
            _StepIcon(
              icon: '❤️',
              label: context.tr('splash_flow_match'),
              progress: step3,
              color: const Color(0xFFFF4D6D),
              textColor: colors.textSecondary,
            ),
          ],
        );
      },
    );
  }

  double _interval(double t, double begin, double end) {
    return ((t - begin) / (end - begin)).clamp(0.0, 1.0);
  }
}

// ─── Step Icon ─────────────────────────────────────────────────────────────

class _StepIcon extends StatelessWidget {
  final String icon;
  final String label;
  final double progress;
  final Color color;
  final Color textColor;

  const _StepIcon({
    required this.icon,
    required this.label,
    required this.progress,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final scale = Curves.elasticOut.transform(progress);
    final opacity = Curves.easeIn.transform(progress.clamp(0.0, 0.5) * 2);

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: 0.3 + 0.7 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(
                  color: color.withValues(alpha: 0.5 * opacity),
                  width: 1.5,
                ),
                boxShadow: progress > 0.5
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25 * progress),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                icon,
                style: TextStyle(fontSize: 20, height: 1),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: textColor.withValues(alpha: opacity),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Connector Line ────────────────────────────────────────────────────────

class _ConnectorLine extends StatelessWidget {
  final double progress;
  final Color color;

  const _ConnectorLine({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18), // align with circles
      child: SizedBox(
        width: 32,
        height: 2,
        child: CustomPaint(
          painter: _LinePainter(progress: progress, color: color),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _LinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final endX = size.width * Curves.easeOut.transform(progress);
    canvas.drawLine(Offset.zero, Offset(endX, 0), paint);

    // Glow dot at the tip
    if (progress > 0.1 && progress < 1.0) {
      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(endX, 0), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.progress != progress;
}
