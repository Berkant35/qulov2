import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/quiz/models/badge_config.dart';

class CelebrationBadgeSection extends StatelessWidget {
  final Animation<double> badgeScale;
  final Animation<double> badgeOpacity;
  final Listenable animation;
  final BadgeConfig config;
  final bool matched;

  const CelebrationBadgeSection({
    super.key,
    required this.badgeScale,
    required this.badgeOpacity,
    required this.animation,
    required this.config,
    required this.matched,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: badgeOpacity.value,
          child: Transform.scale(
            scale: badgeScale.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BadgeChip(config: config),
          const SizedBox(height: AppSpacing.lg),
          Text(
            matched
                ? context.tr('quiz_match_title')
                : context.tr('quiz_failed_title'),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: matched ? AppColors.primary : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: matched ? 32 : 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeConfig config;

  const _BadgeChip({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: config.gradientColors),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: [
          BoxShadow(
            color: config.gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 24, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.tr(config.labelKey),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
