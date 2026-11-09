import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/quiz/mixins/match_celebration_screen_mixin.dart';
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
    with TickerProviderStateMixin, MatchCelebrationScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Raw Scaffold: yari saydam scrim ustunde kutlama animasyonu (Scaffold
    // Kurali istisnasi) — AppScaffold'un arka plan boyasi ve AppBar'i istenmez.
    return Scaffold(
      backgroundColor: AppColors.scrimBase.withValues(alpha: 0.95),
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
                  badgeScale: badgeScale,
                  badgeOpacity: badgeOpacity,
                  animation: badgeController,
                  config: BadgeConfig.fromPerformance(
                    matched: widget.matched,
                    performanceBadge: widget.performanceBadge,
                  ),
                  matched: widget.matched,
                ),
                const SizedBox(height: AppSpacing.xxl),
                CelebrationPhotoSection(
                  photoSlide: photoSlide,
                  animation: photoController,
                  myPhotoUrl: widget.myPhotoUrl,
                  targetPhotoUrl: widget.targetPhotoUrl,
                  matched: widget.matched,
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeTransition(
                  opacity: statsOpacity,
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
