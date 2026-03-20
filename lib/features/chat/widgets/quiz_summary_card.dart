import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/quiz_summary_model.dart';

class QuizSummaryCard extends StatelessWidget {
  final QuizSummaryModel summary;
  final String currentUserId;
  final VoidCallback? onDismiss;

  const QuizSummaryCard({
    super.key,
    required this.summary,
    required this.currentUserId,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSolver = summary.solverId == currentUserId;
    final timeStr = summary.totalTimeSpent != null ? '${summary.totalTimeSpent}' : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.quiz_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.tr('chat_quiz_summary'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              // Performance badge
              _PerformanceBadge(badge: summary.performanceBadge),
              if (onDismiss != null) ...[
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Stats line
          Text(
            isSolver
                ? context
                    .tr('chat_quiz_summary_solved')
                    .replaceAll('{count}', '${summary.totalCorrect}/${summary.totalQuestions}')
                    .replaceAll('{time}', timeStr)
                : context
                    .tr('chat_quiz_summary_solved')
                    .replaceAll('{count}', '${summary.totalCorrect}/${summary.totalQuestions}')
                    .replaceAll('{time}', timeStr),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          // Powers used
          if (summary.totalPowersUsed > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.flash_on, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  '${summary.totalPowersUsed} ${context.tr('quiz_result_powers_used').toLowerCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceBadge extends StatelessWidget {
  final String badge;
  const _PerformanceBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _badgeConfig(context, badge);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: config.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: config.color),
          const SizedBox(width: 4),
          Text(
            context.tr('quiz_result_$badge'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _badgeConfig(BuildContext context, String badge) {
    switch (badge) {
      case 'flawless':
        return _BadgeConfig(color: AppColors.success, icon: Icons.auto_awesome);
      case 'speed_solver':
        return _BadgeConfig(color: AppColors.info, icon: Icons.speed);
      case 'power_master':
        return _BadgeConfig(color: AppColors.warning, icon: Icons.flash_on);
      case 'determined':
        return _BadgeConfig(color: AppColors.primary, icon: Icons.psychology);
      default:
        return _BadgeConfig(color: context.appColors.textHint, icon: Icons.emoji_events_outlined);
    }
  }
}

class _BadgeConfig {
  final Color color;
  final IconData icon;
  const _BadgeConfig({required this.color, required this.icon});
}
