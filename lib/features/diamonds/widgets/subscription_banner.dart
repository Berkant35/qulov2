import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';

class SubscriptionBanner extends StatelessWidget {
  final SubscriptionInfo subscription;
  final VoidCallback onViewPlans;

  const SubscriptionBanner({
    super.key,
    required this.subscription,
    required this.onViewPlans,
  });

  @override
  Widget build(BuildContext context) {
    if (subscription.isActive) {
      return _ActivePlanBadge(subscription: subscription);
    }
    return _UpgradeBanner(onViewPlans: onViewPlans);
  }
}

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onViewPlans;

  const _UpgradeBanner({required this.onViewPlans});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return GestureDetector(
      onTap: onViewPlans,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.cardPadding,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryDark.withValues(alpha: 0.5),
              colors.primary.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Crown icon with glow
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.3),
                    colors.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: AppIcon(
                  QIcons.crown,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('premium_cta'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('premium_benefits'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.2),
              ),
              child: QIcon(
                QIcons.icChevronRight,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePlanBadge extends StatelessWidget {
  final SubscriptionInfo subscription;

  const _ActivePlanBadge({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planName = subscription.isPremium ? 'Premium' : 'Plus';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: context.appColors.purpleGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              planName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('active_plan'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subscription.expiresAt != null)
                  Text(
                    context.tr('expires_at').replaceAll(
                          '{date}',
                          _formatDate(subscription.expiresAt!),
                        ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
