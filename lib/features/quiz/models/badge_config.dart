import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class BadgeConfig {
  final String labelKey;
  final IconData icon;
  final List<Color> gradientColors;

  const BadgeConfig({
    required this.labelKey,
    required this.icon,
    required this.gradientColors,
  });

  factory BadgeConfig.fromPerformance({
    required bool matched,
    required String performanceBadge,
  }) {
    if (matched) {
      return switch (performanceBadge) {
        'flawless' => const BadgeConfig(
            labelKey: 'quiz_badge_flawless',
            icon: Icons.stars,
            gradientColors: [Colors.amber, Colors.orange],
          ),
        'speed_solver' => const BadgeConfig(
            labelKey: 'quiz_badge_speed_solver',
            icon: Icons.bolt,
            gradientColors: [Colors.blue, Colors.cyan],
          ),
        'power_master' => BadgeConfig(
            labelKey: 'quiz_badge_power_master',
            icon: Icons.auto_awesome,
            gradientColors: [AppColors.primary, Colors.deepPurple],
          ),
        'determined' => const BadgeConfig(
            labelKey: 'quiz_badge_determined',
            icon: Icons.psychology,
            gradientColors: [Colors.green, Colors.teal],
          ),
        _ => BadgeConfig(
            labelKey: 'quiz_badge_matched',
            icon: Icons.favorite,
            gradientColors: [AppColors.primary, Colors.pink],
          ),
      };
    }
    return BadgeConfig(
      labelKey: 'quiz_badge_failed',
      icon: Icons.close,
      gradientColors: [AppColors.error, Colors.red],
    );
  }
}
