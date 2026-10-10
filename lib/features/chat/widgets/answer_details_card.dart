import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/chat/widgets/option_badge.dart';

/// Sonuç ekranında verilen cevap, doğru cevap ve (varsa) harcanan süre.
class AnswerDetailsCard extends StatelessWidget {
  final String answeredOption;
  final String correctOption;
  final bool isCorrect;
  final int? timeSpent;

  const AnswerDetailsCard({
    super.key,
    required this.answeredOption,
    required this.correctOption,
    required this.isCorrect,
    this.timeSpent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correctColor = context.appColors.success;
    final answeredColor = isCorrect ? correctColor : context.appColors.error;
    final seconds = timeSpent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: answeredColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OptionBadge(
              label: context.tr('result_your_answer'),
              option: answeredOption,
              color: answeredColor,
            ),
          ),
          Container(width: 1, height: 36, color: theme.dividerColor),
          Expanded(
            child: OptionBadge(
              label: context.tr('result_correct_label'),
              option: correctOption,
              color: correctColor,
            ),
          ),
          if (seconds != null) ...[
            Container(width: 1, height: 36, color: theme.dividerColor),
            Expanded(
              child: Column(
                children: [
                  Text(
                    context.tr('result_time'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.fmt.seconds(seconds),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
