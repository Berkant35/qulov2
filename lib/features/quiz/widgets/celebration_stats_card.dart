import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/quiz/widgets/celebration_stat_row.dart';

class CelebrationStatsCard extends StatelessWidget {
  final int totalCorrect;
  final int totalQuestions;
  final int totalTimeSpent;
  final int powersUsed;

  const CelebrationStatsCard({
    super.key,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.totalTimeSpent,
    required this.powersUsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          CelebrationStatRow(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.secondary,
            label: context
                .tr('quiz_stat_correct')
                .replaceAll('{correct}', '$totalCorrect')
                .replaceAll('{total}', '$totalQuestions'),
          ),
          const SizedBox(height: AppSpacing.md),
          CelebrationStatRow(
            icon: Icons.timer_outlined,
            iconColor: AppColors.info,
            label: context
                .tr('quiz_stat_time')
                .replaceAll('{time}', '$totalTimeSpent'),
          ),
          if (powersUsed > 0) ...[
            const SizedBox(height: AppSpacing.md),
            CelebrationStatRow(
              icon: Icons.bolt,
              iconColor: AppColors.primary,
              label: context
                  .tr('quiz_stat_powers')
                  .replaceAll('{count}', '$powersUsed'),
            ),
          ],
        ],
      ),
    );
  }
}
