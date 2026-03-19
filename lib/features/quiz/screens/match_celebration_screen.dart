import 'package:flutter/material.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/quiz/models/badge_config.dart';
import 'package:qulo_v2/features/quiz/widgets/celebration_badge_section.dart';
import 'package:qulo_v2/features/quiz/widgets/celebration_buttons.dart';
import 'package:qulo_v2/features/quiz/widgets/celebration_photo_section.dart';
import 'package:qulo_v2/features/quiz/widgets/celebration_stats_card.dart';

class MatchCelebrationScreen extends StatefulWidget {
  final bool matched;
  final int totalCorrect;
  final int totalQuestions;
  final int totalTimeSpent;
  final int powersUsed;
  final String performanceBadge;
  final String? targetPhotoUrl;
  final String? myPhotoUrl;
  final VoidCallback? onStartChat;
  final VoidCallback onGoBack;

  const MatchCelebrationScreen({
    super.key,
    required this.matched,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.totalTimeSpent,
    required this.powersUsed,
    required this.performanceBadge,
    this.targetPhotoUrl,
    this.myPhotoUrl,
    this.onStartChat,
    required this.onGoBack,
  });

  @override
  State<MatchCelebrationScreen> createState() =>
      _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _badgeController;
  late final AnimationController _photoController;
  late final AnimationController _statsController;

  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _photoSlide;
  late final Animation<double> _statsOpacity;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _logScreenShown();
  }

  void _initAnimations() {
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _badgeScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );
    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _photoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _photoSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _photoController, curve: Curves.easeOutBack),
    );

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _statsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeIn),
    );
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _badgeController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _photoController.forward();
    _statsController.forward();
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

  @override
  void dispose() {
    _badgeController.dispose();
    _photoController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CelebrationBadgeSection(
                  badgeScale: _badgeScale,
                  badgeOpacity: _badgeOpacity,
                  animation: _badgeController,
                  config: BadgeConfig.fromPerformance(
                    matched: widget.matched,
                    performanceBadge: widget.performanceBadge,
                  ),
                  matched: widget.matched,
                ),
                const SizedBox(height: AppSpacing.xxl),
                CelebrationPhotoSection(
                  photoSlide: _photoSlide,
                  animation: _photoController,
                  myPhotoUrl: widget.myPhotoUrl,
                  targetPhotoUrl: widget.targetPhotoUrl,
                  matched: widget.matched,
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeTransition(
                  opacity: _statsOpacity,
                  child: Column(
                    children: [
                      CelebrationStatsCard(
                        totalCorrect: widget.totalCorrect,
                        totalQuestions: widget.totalQuestions,
                        totalTimeSpent: widget.totalTimeSpent,
                        powersUsed: widget.powersUsed,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CelebrationButtons(
                        matched: widget.matched,
                        onStartChat: widget.onStartChat,
                        onGoBack: widget.onGoBack,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
