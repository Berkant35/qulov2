import 'package:flutter/material.dart';

/// Envanter sayısı ARTINCA [child]'ı kısa bir "pulse" ile vurgular: büyü-küçül + [glowColor]
/// ışıması. Azalma ya da aynı sayı animasyon başlatmaz; ilk çizimde oynamaz.
///
/// Güç dükkanı kartı ve güç satın alma sayfası satırı ortak kullanır (satın alma geri bildirimi).
class InventoryPulse extends StatefulWidget {
  const InventoryPulse({
    super.key,
    required this.count,
    required this.glowColor,
    required this.child,
  });

  final int count;
  final Color glowColor;
  final Widget child;

  static const duration = Duration(milliseconds: 400);

  @override
  State<InventoryPulse> createState() => _InventoryPulseState();
}

class _InventoryPulseState extends State<InventoryPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: InventoryPulse.duration);

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 60,
    ),
  ]).animate(_controller);

  late final Animation<double> _glow = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 0.6).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.6, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(InventoryPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _controller.isAnimating
              ? [
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: _glow.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
