import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/icons/icon_ref.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class QuizResultContent extends StatelessWidget {
  final bool matched;
  final int totalCorrect;
  final int totalQuestions;
  final int totalTimeSpent;
  final int powersUsed;
  final String performanceBadge;
  final VoidCallback? onStartChat;
  final VoidCallback onGoBack;

  const QuizResultContent({
    super.key,
    required this.matched,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.totalTimeSpent,
    required this.powersUsed,
    required this.performanceBadge,
    this.onStartChat,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Top icon ───
            _TopIcon(matched: matched),
            const SizedBox(height: AppSpacing.lg),

            // ─── Title ───
            Text(
              matched
                  ? context.tr('quiz_result_matched')
                  : context.tr('quiz_result_not_matched'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: matched ? context.appColors.secondary : context.appColors.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ─── Badge ───
            if (performanceBadge != 'none') ...[
              _Badge(performanceBadge: performanceBadge),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ─── Stats ───
            _Stats(
              totalCorrect: totalCorrect,
              totalQuestions: totalQuestions,
              totalTimeSpent: totalTimeSpent,
              powersUsed: powersUsed,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ─── Buttons ───
            if (matched && onStartChat != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStartChat,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appColors.secondary,
                    foregroundColor: context.appColors.background,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(context.tr('quiz_result_start_chat')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onGoBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(context.tr('quiz_result_go_back')),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _TopIcon extends StatelessWidget {
  final bool matched;

  const _TopIcon({required this.matched});

  @override
  Widget build(BuildContext context) {
    if (matched) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.appColors.secondarySurface,
        ),
        child: Center(
          child: AppIcon(QIcons.heart, size: 40, color: context.appColors.secondary),
        ),
      );
    }
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x1ACF6679),
      ),
      child: Center(
        child: QIcon(QIcons.icX, size: 40, color: context.appColors.error),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String performanceBadge;

  const _Badge({required this.performanceBadge});

  (dynamic icon, Color color, String labelKey) _badgeConfig(BuildContext context) {
    return switch (performanceBadge) {
      'flawless' => (QIcons.crown, AppColors.gold, 'quiz_result_flawless'),
      'speed_solver' => (QIcons.bolt, context.appColors.info, 'quiz_result_speed_solver'),
      'power_master' => (QIcons.icGem, context.appColors.primary, 'quiz_result_power_master'),
      'determined' => (QIcons.icFire, context.appColors.warning, 'quiz_result_determined'),
      _ => (QIcons.icTarget, context.appColors.textSecondary, 'quiz_result_determined'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, labelKey) = _badgeConfig(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon is IconRef)
            AppIcon(icon, size: 20, color: color)
          else
            QIcon(icon as String, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.tr(labelKey),
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final int totalCorrect;
  final int totalQuestions;
  final int totalTimeSpent;
  final int powersUsed;

  const _Stats({
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
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          _StatRow(
            icon: QIcons.icCheckCircle,
            iconColor: context.appColors.secondary,
            label: context
                .tr('quiz_result_correct_count')
                .replaceAll('{correct}', '$totalCorrect')
                .replaceAll('{total}', '$totalQuestions'),
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatRow(
            icon: QIcons.icClock,
            iconColor: context.appColors.info,
            label: '${context.tr('quiz_result_time_spent')}: ${totalTimeSpent}s',
            theme: theme,
          ),
          if (powersUsed > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _StatRow(
              icon: QIcons.bolt,
              iconColor: context.appColors.primary,
              label: '${context.tr('quiz_result_powers_used')}: $powersUsed',
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final dynamic icon;
  final Color iconColor;
  final String label;
  final ThemeData theme;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon is IconRef)
          AppIcon(icon, size: 18, color: iconColor)
        else
          QIcon(icon as String, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
