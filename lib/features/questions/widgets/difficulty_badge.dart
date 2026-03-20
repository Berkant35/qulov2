import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(context);

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: config.color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.tr('analytics_difficulty_$difficulty'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    if (difficulty == 'legendary') {
      chip = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: context.appColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: chip,
      );
    }

    return chip;
  }

  _DifficultyConfig _getConfig(BuildContext context) {
    switch (difficulty) {
      case 'easy':
        return _DifficultyConfig(
          color: context.appColors.success,
          icon: Icons.sentiment_satisfied_alt,
        );
      case 'medium':
        return _DifficultyConfig(
          color: context.appColors.warning,
          icon: Icons.trending_up,
        );
      case 'hard':
        return _DifficultyConfig(
          color: const Color(0xFFFF7043),
          icon: Icons.local_fire_department,
        );
      case 'legendary':
        return _DifficultyConfig(
          color: context.appColors.primary,
          icon: Icons.auto_awesome,
        );
      default:
        return _DifficultyConfig(
          color: context.appColors.textHint,
          icon: Icons.help_outline,
        );
    }
  }
}

class _DifficultyConfig {
  final Color color;
  final IconData icon;

  const _DifficultyConfig({
    required this.color,
    required this.icon,
  });
}
