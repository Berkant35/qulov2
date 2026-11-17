import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Tek rozet çipi: "🎤 Sesli". Kategori / dil çipleriyle aynı görünüm.
class QuestionMediaBadge extends StatelessWidget {
  final String emoji;
  final String label;

  const QuestionMediaBadge({super.key, required this.emoji, required this.label});

  /// Kategori / dil çipleriyle aynı küçük yazı boyutu.
  static const _fontSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.onScrim.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.onScrim.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$emoji $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onScrim,
              fontSize: _fontSize,
            ),
      ),
    );
  }
}
