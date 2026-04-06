import 'package:flutter/material.dart';

/// Çocuk widget'ları staggered fade-in + slide-up animasyonuyla gösterir.
///
/// Her çocuk sırayla 100ms arayla belirir.
/// İlk eleman scale animasyonu alır (logo için), diğerleri slide-up.
class StaggeredColumn extends StatefulWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration totalDuration;
  final Duration staggerDelay;
  final double slideOffset;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.totalDuration = const Duration(milliseconds: 1200),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.slideOffset = 20.0,
  });

  @override
  State<StaggeredColumn> createState() => StaggeredColumnState();
}

class StaggeredColumnState extends State<StaggeredColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    );
    _buildAnimations();
  }

  void _buildAnimations() {
    final count = widget.children.length;
    final totalMs = widget.totalDuration.inMilliseconds;
    final staggerMs = widget.staggerDelay.inMilliseconds;
    final itemDurationMs = totalMs - (count - 1) * staggerMs;

    _fadeAnimations = List.generate(count, (i) {
      final startMs = i * staggerMs;
      final endMs = startMs + itemDurationMs;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(
          startMs / totalMs,
          (endMs / totalMs).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });

    _slideAnimations = List.generate(count, (i) {
      return Tween<Offset>(
        begin: Offset(0, widget.slideOffset),
        end: Offset.zero,
      ).animate(_fadeAnimations[i]);
    });

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      _fadeAnimations.isNotEmpty ? _fadeAnimations[0] : _controller,
    );
  }

  /// Dışarıdan animasyonu başlatmak için.
  void forward() {
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: List.generate(widget.children.length, (i) {
        if (i == 0) {
          // Logo — fade + scale
          return FadeTransition(
            opacity: _fadeAnimations[i],
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.children[i],
            ),
          );
        }
        // Diğerleri — fade + slide-up
        return FadeTransition(
          opacity: _fadeAnimations[i],
          child: AnimatedBuilder(
            animation: _slideAnimations[i],
            builder: (context, child) {
              return Transform.translate(
                offset: _slideAnimations[i].value,
                child: child,
              );
            },
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}
