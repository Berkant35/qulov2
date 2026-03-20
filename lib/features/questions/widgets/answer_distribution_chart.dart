import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class AnswerDistributionChart extends StatelessWidget {
  final Map<String, dynamic> distribution;

  const AnswerDistributionChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = distribution.values.fold<int>(
      0,
      (prev, v) => (v as int) > prev ? v : prev,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('analytics_answer_distribution'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(4, (i) {
          final key = 'answer_${i + 1}';
          final count = (distribution[key] ?? 0) as int;
          final fraction = maxVal > 0 ? count / maxVal : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    context
                        .tr('analytics_answer_n')
                        .replaceAll('{n}', '${i + 1}'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.appColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: context.appColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.appColors.primary.withValues(
                          alpha: 0.4 + fraction * 0.6,
                        ),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
