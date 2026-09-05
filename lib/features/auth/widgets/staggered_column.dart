import 'dart:async';

import 'package:flutter/material.dart';

/// Çocuk widget'ları staggered fade-in + slide-up animasyonuyla gösterir.
///
/// Her çocuk sırayla belirir. İlk eleman scale animasyonu alır (logo için),
/// diğerleri slide-up. Interval hesaplaması child sayısından bağımsız olarak
/// güvenli aralıklar üretir (begin < end her zaman).
class StaggeredColumn extends StatefulWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration totalDuration;
  final double slideOffset;

  /// Emniyet suresi: [forward] bu sure icinde disaridan cagrilmazsa kolon
  /// kendini acar (orn. arka plan videosu yuklenemedi/gecikti).
  final Duration? autoForwardAfter;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.totalDuration = const Duration(milliseconds: 1200),
    this.slideOffset = 20.0,
    this.autoForwardAfter,
  });

  @override
  State<StaggeredColumn> createState() => StaggeredColumnState();
}

class StaggeredColumnState extends State<StaggeredColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _scaleAnimation;
  Timer? _autoForwardTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    );
    _buildAnimations();
    final fallback = widget.autoForwardAfter;
    if (fallback != null) {
      _autoForwardTimer = Timer(fallback, forward);
    }
  }

  void _buildAnimations() {
    final count = widget.children.length;
    if (count == 0) {
      _fadeAnimations = [];
      _slideAnimations = [];
      _scaleAnimation = _controller;
      return;
    }

    // Stagger dağılımı: başlangıçlar ilk %60'a yayılır,
    // her öğe %40 süre boyunca animasyon yapar.
    // Bu hesaplama child sayısından bağımsız olarak begin < end garanti eder.
    const staggerRange = 0.6;
    const itemDuration = 0.4;
    final staggerStep =
        count > 1 ? staggerRange / (count - 1) : 0.0;

    _fadeAnimations = List.generate(count, (i) {
      final begin = (i * staggerStep).clamp(0.0, 1.0);
      final end = (begin + itemDuration).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );
    });

    _slideAnimations = List.generate(count, (i) {
      return Tween<Offset>(
        begin: Offset(0, widget.slideOffset),
        end: Offset.zero,
      ).animate(_fadeAnimations[i]);
    });

    // İlk eleman (logo) için scale animasyonu
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      _fadeAnimations[0],
    );
  }

  /// Dışarıdan animasyonu başlatmak için (tekrar cagrilmasi zararsiz).
  void forward() {
    _autoForwardTimer?.cancel();
    if (!mounted) return;
    _controller.forward();
  }

  @override
  void dispose() {
    _autoForwardTimer?.cancel();
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
