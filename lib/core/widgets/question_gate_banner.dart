import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class QuestionGateBanner extends StatelessWidget {
  final int questionCount;
  final int profileCompletion;
  final VoidCallback onAddQuestions;

  const QuestionGateBanner({
    super.key,
    required this.questionCount,
    required this.profileCompletion,
    required this.onAddQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onAddQuestions,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.appColors.primary.withValues(alpha: 0.12),
              context.appColors.secondary.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            QIcon(QIcons.icLock, color: context.appColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${context.tr('question_nudge_banner_compact')} — $questionCount/2 ${context.tr('question_word')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            QIcon(QIcons.icPlus, color: context.appColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
