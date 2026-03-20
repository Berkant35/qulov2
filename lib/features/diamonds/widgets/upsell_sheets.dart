// @deprecated: Use PaywallBottomSheetContent instead. These sheets are not connected anywhere.
// Will be removed in a future cleanup.
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/purchase_grid.dart';

// ─── Base Upsell Sheet ───
// Shared layout for all upsell bottom sheets
class _BaseUpsellSheet extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback? onDismiss;

  const _BaseUpsellSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.hintColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          icon,
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          content,
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onDismiss ?? () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                context.tr('maybe_later'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Upsell Sheet ───
// Used for: onboarding upsell, first match upsell
class PremiumUpsellSheet extends StatelessWidget {
  final bool isFirstMatch;
  final VoidCallback? onPlusTap;
  final VoidCallback? onPremiumTap;
  final VoidCallback? onDismiss;

  const PremiumUpsellSheet({
    super.key,
    this.isFirstMatch = false,
    this.onPlusTap,
    this.onPremiumTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseUpsellSheet(
      icon: const DiamondIcon.purple(size: 48),
      title: isFirstMatch
          ? context.tr('first_match_congrats')
          : context.tr('premium_cta'),
      subtitle: isFirstMatch
          ? context.tr('want_more_matches')
          : context.tr('unlock_unlimited'),
      onDismiss: onDismiss,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FeatureRow(
            icon: Icons.all_inclusive,
            text: context.tr('sub_premium_swipes'),
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureRow(
            icon: Icons.diamond_outlined,
            text: context.tr('sub_premium_diamonds'),
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureRow(
            icon: Icons.undo,
            text: context.tr('sub_premium_undos'),
          ),
          const SizedBox(height: AppSpacing.md),
          _FeatureRow(
            icon: Icons.bolt,
            text: context.tr('sub_premium_boost'),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label:
                '${context.tr('sub_plan_plus')} — ${context.tr('sub_price_plus')}',
            variant: AppButtonVariant.secondary,
            onPressed: onPlusTap,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label:
                '${context.tr('sub_plan_premium')} — ${context.tr('sub_price_premium')}',
            onPressed: onPremiumTap,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            color: context.appColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: context.appColors.primary, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ─── Consumable Upsell Sheet ───
// Used for: diamond empty, boost need
class ConsumableUpsellSheet extends StatelessWidget {
  final bool isBoostNeed;
  final ValueChanged<PurchasePackage>? onPurchase;
  final VoidCallback? onDismiss;

  const ConsumableUpsellSheet({
    super.key,
    this.isBoostNeed = false,
    this.onPurchase,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseUpsellSheet(
      icon: const DiamondIcon.purple(size: 48),
      title: context.tr('diamonds_empty'),
      subtitle: context.tr('get_diamonds'),
      onDismiss: onDismiss,
      content: PurchaseGrid(onPurchase: onPurchase),
    );
  }
}

// ─── Swipe Limit Sheet ───
// Used for: daily swipe limit reached
class SwipeLimitSheet extends StatelessWidget {
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  const SwipeLimitSheet({
    super.key,
    this.onUpgrade,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseUpsellSheet(
      icon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: context.appColors.primarySurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.swipe,
          color: context.appColors.primary,
          size: 32,
        ),
      ),
      title: context.tr('swipe_limit_reached'),
      subtitle: context.tr('unlock_unlimited'),
      onDismiss: onDismiss,
      content: AppButton(
        label: context.tr('upgrade_now'),
        onPressed: onUpgrade,
      ),
    );
  }
}
