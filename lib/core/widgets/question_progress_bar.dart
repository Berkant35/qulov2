import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class QuestionProgressBar extends StatelessWidget {
  final int questionCount;
  final int requiredCount;
  final double minHeight;

  const QuestionProgressBar({
    super.key,
    required this.questionCount,
    this.requiredCount = 2,
    this.minHeight = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (questionCount / requiredCount).clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: minHeight,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('question_nudge_progress')
              .replaceAll('{count}', '$questionCount'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
