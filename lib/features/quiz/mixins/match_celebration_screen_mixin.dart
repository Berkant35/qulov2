import 'package:flutter/material.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/quiz/screens/match_celebration_screen.dart';

/// [MatchCelebrationScreen] logic'i: rozet → fotoğraf/istatistik giriş
/// animasyonları ve ekran gösterim analitiği.
mixin MatchCelebrationScreenMixin
    on
        State<MatchCelebrationScreen>,
        TickerProviderStateMixin<MatchCelebrationScreen> {
  late final AnimationController badgeController;
  late final AnimationController photoController;
  late final AnimationController statsController;

  late final Animation<double> badgeScale;
  late final Animation<double> badgeOpacity;
  late final Animation<double> photoSlide;
  late final Animation<double> statsOpacity;

  void initMixin() {
    _initAnimations();
    _startAnimations();
    _logScreenShown();
  }

  void disposeMixin() {
    badgeController.dispose();
    photoController.dispose();
    statsController.dispose();
  }

  void _initAnimations() {
    badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    badgeScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: badgeController, curve: Curves.elasticOut),
    );
    badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: badgeController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    photoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    photoSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: photoController, curve: Curves.easeOutBack),
    );

    statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    statsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: statsController, curve: Curves.easeIn),
    );
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    badgeController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    photoController.forward();
    statsController.forward();
  }

  void _logScreenShown() {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.matchCelebrationShown,
      params: {
        AnalyticsEvents.paramMatched: widget.matched.toString(),
        AnalyticsEvents.paramBadge: widget.performanceBadge,
      },
    );
  }
}
