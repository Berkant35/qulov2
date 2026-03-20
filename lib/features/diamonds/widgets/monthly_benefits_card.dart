import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';

class MonthlyBenefitsCard extends StatelessWidget {
  final DailyStats stats;
  final bool isFree;
  final VoidCallback? onUpgrade;

  const MonthlyBenefitsCard({
    super.key,
    required this.stats,
    required this.isFree,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isFree
              ? theme.colorScheme.outline.withValues(alpha: 0.3)
              : context.appColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('monthly_benefits_title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Daily Discovers
          _BenefitRow(
            icon: QIcons.icCompass,
            label: context.tr('benefit_daily_discovers'),
            value: stats.isDiscoverUnlimited
                ? context.tr('benefit_unlimited')
                : '${stats.dailyDiscoversUsed}/${stats.dailyDiscoversLimit}',
            progress: stats.isDiscoverUnlimited
                ? null
                : stats.dailyDiscoversLimit > 0
                    ? stats.dailyDiscoversUsed / stats.dailyDiscoversLimit
                    : 0,
            color: context.appColors.primary,
          ),

          // Question Slots
          _BenefitRow(
            icon: QIcons.icHelpCircle,
            label: context.tr('benefit_question_slots'),
            value: '${stats.questionsCreated}/${stats.questionsLimit}',
            progress: stats.questionsLimit > 0
                ? stats.questionsCreated / stats.questionsLimit
                : 0,
            color: context.appColors.secondary,
          ),

          // Daily Undos
          _BenefitRow(
            icon: QIcons.icSkipForward,
            label: context.tr('benefit_daily_undos'),
            value: stats.dailyUndosLimit == 0
                ? context.tr('benefit_none')
                : stats.isUndoUnlimited
                    ? context.tr('benefit_unlimited')
                    : '${stats.dailyUndosUsed}/${stats.dailyUndosLimit}',
            progress: stats.dailyUndosLimit == 0
                ? null
                : stats.isUndoUnlimited
                    ? null
                    : stats.dailyUndosLimit > 0
                        ? stats.dailyUndosUsed / stats.dailyUndosLimit
                        : 0,
            color: context.appColors.primary,
          ),

          // Monthly Diamonds
          _BenefitRow(
            iconWidget: const DiamondIcon.purple(size: 16),
            label: context.tr('benefit_monthly_diamonds'),
            value: stats.monthlyPurpleBonus > 0
                ? '${stats.monthlyPurpleBonus} \u2713'
                : context.tr('benefit_none'),
            color: context.appColors.primary,
          ),

          // Passport Mode
          _BenefitRow(
            icon: QIcons.icGlobe,
            label: context.tr('benefit_passport'),
            value: stats.passportMode
                ? context.tr('benefit_active')
                : context.tr('benefit_inactive'),
            color: stats.passportMode ? context.appColors.secondary : theme.colorScheme.onSurfaceVariant,
          ),

          // Ads
          _BenefitRow(
            icon: QIcons.icEyeOff,
            label: context.tr('benefit_ads'),
            value: stats.hasAds
                ? context.tr('benefit_has_ads')
                : context.tr('benefit_no_ads'),
            color: stats.hasAds ? theme.colorScheme.onSurfaceVariant : context.appColors.secondary,
            showDivider: false,
          ),

          // Upgrade CTA for free users
          if (isFree && onUpgrade != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onUpgrade,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.appColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  context.tr('get_started'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: context.appColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String? icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  final double? progress;
  final Color color;
  final bool showDivider;

  const _BenefitRow({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
    this.progress,
    required this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (iconWidget != null)
                SizedBox(width: 16, height: 16, child: iconWidget!)
              else
                QIcon(icon!, size: 16, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                          color: color,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ],
    );
  }
}
