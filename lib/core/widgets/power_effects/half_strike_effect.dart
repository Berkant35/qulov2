import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_player.dart';

/// HALF: elenen şık önce üstü çizilir, sonra opaklığı düşer ve yüksekliği kapanır
/// (tek hareket: çizgi çekilirken şık yerinde ve görünür kalır).
///
/// [removed] `false → true` olunca oynar, `true → false` olunca geri açılır. İlk build
/// zaten kaldırılmışsa kapalı açılır. Kaldırılan şık dokunuşu yakalamaz.
class HalfStrikeEffect extends StatefulWidget {
  const HalfStrikeEffect({super.key, required this.child, required this.removed});

  final Widget child;
  final bool removed;

  @visibleForTesting
  static const Key strikeKey = ValueKey('half_strike_line');

  @override
  State<HalfStrikeEffect> createState() => _HalfStrikeEffectState();
}

class _HalfStrikeEffectState extends State<HalfStrikeEffect>
    with SingleTickerProviderStateMixin, PowerEffectPlayer<HalfStrikeEffect> {
  /// Çizgi, giriş süresinin ilk %45'inde çekilir; kalanında şık kaybolur.
  static const _strikeEnd = 0.45;

  late final Animation<double> _strike = phase(0, _strikeEnd);
  late final Animation<double> _collapse = Tween<double>(begin: 1, end: 0).animate(phase(_strikeEnd, 1));

  @override
  void initState() {
    super.initState();
    settleAt(widget.removed ? 1 : 0);
  }

  @override
  void didUpdateWidget(HalfStrikeEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removed == oldWidget.removed) return;
    widget.removed ? playIn() : playOut();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.removed,
      child: SizeTransition(
        sizeFactor: _collapse,
        axisAlignment: -1,
        child: FadeTransition(
          opacity: _collapse,
          child: CustomPaint(
            key: HalfStrikeEffect.strikeKey,
            foregroundPainter: _StrikePainter(
              progress: _strike,
              color: context.appColors.textSecondary,
              textDirection: Directionality.of(context),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Şıkkın ortasından, okuma yönünde çekilen ince çizgi.
class _StrikePainter extends CustomPainter {
  _StrikePainter({required this.progress, required this.color, required this.textDirection})
      : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final length = (size.width - 2 * AppSpacing.lg) * progress.value;
    if (length <= 0) return;
    final rtl = textDirection == TextDirection.rtl;
    final startX = rtl ? size.width - AppSpacing.lg : AppSpacing.lg;
    final endX = rtl ? startX - length : startX + length;
    final y = size.height / 2;
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      Paint()
        ..color = color
        ..strokeWidth = AppSpacing.xxs
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.textDirection != textDirection;
}
