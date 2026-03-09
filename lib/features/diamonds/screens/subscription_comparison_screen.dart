import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/diamonds/widgets/celebration_dialog.dart';

class SubscriptionComparisonScreen extends ConsumerWidget {
  const SubscriptionComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);
    final currentPlan = subAsync.valueOrNull;
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('sub_choose_plan'),
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          children: [
            // Free plan — compact
            _CompactPlanRow(
              name: context.tr('sub_plan_free'),
              price: context.tr('sub_price_free'),
              isCurrent: currentPlan?.isFree ?? true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Plus plan
            _PlanCard(
              name: context.tr('sub_plan_plus'),
              price: context.tr('sub_price_plus'),
              features: [
                _Feature(QIcons.icCompass, context.tr('sub_plus_discovers')),
                _Feature(QIcons.icHelpCircle, context.tr('sub_plus_questions')),
                _Feature.widget(const DiamondIcon.purple(size: 16), context.tr('sub_plus_diamonds')),
                _Feature(QIcons.icSkipForward, context.tr('sub_plus_undos')),
                _Feature(QIcons.icEyeOff, context.tr('sub_plus_no_ads')),
              ],
              isRecommended: false,
              isCurrent: currentPlan?.isPlus ?? false,
              onSubscribe: () => _handlePurchase(context, ref, 'plus'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Premium plan
            _PlanCard(
              name: context.tr('sub_plan_premium'),
              price: context.tr('sub_price_premium'),
              features: [
                _Feature(QIcons.icCompass, context.tr('sub_premium_discovers')),
                _Feature(QIcons.icHelpCircle, context.tr('sub_premium_questions')),
                _Feature.widget(const DiamondIcon.purple(size: 16), context.tr('sub_premium_diamonds')),
                _Feature(QIcons.icSkipForward, context.tr('sub_premium_undos')),
                _Feature(QIcons.icGlobe, context.tr('sub_premium_passport')),
                _Feature(QIcons.icEyeOff, context.tr('sub_premium_no_ads')),
              ],
              isRecommended: true,
              isCurrent: currentPlan?.isPremium ?? false,
              onSubscribe: () => _handlePurchase(context, ref, 'premium'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Restore purchases
            TextButton(
              onPressed: () => _handleRestore(context, ref),
              child: Text(
                context.tr('sub_restore_purchases'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    WidgetRef ref,
    String plan,
  ) async {
    final productId = plan == 'premium' ? 'qulopremiummonthly' : 'quloplusmonthly2';
    final success = await ref
        .read(subscriptionProvider.notifier)
        .purchaseByProductId(productId);

    if (!context.mounted) return;

    if (success) {
      final isPremium = plan == 'premium';
      final planName = isPremium
          ? context.tr('sub_plan_premium')
          : context.tr('sub_plan_plus');
      final bonus = isPremium ? 1500 : 500;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CelebrationDialog(
          planName: planName,
          diamondBonus: bonus,
          isPremium: isPremium,
        ),
      );

      if (!context.mounted) return;

      // Invalidate providers so diamonds screen shows fresh data
      ref.invalidate(diamondProvider);
      ref.invalidate(subscriptionProvider);
      ref.invalidate(dailyStatsProvider);

      // Navigate to diamonds screen
      final nav = ref.read(navigationServiceProvider);
      nav.pop();
      nav.go(RouteNames.diamonds);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('purchase_failed'))),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('sub_restore_done'))),
      );
    }
  }
}

class _Feature {
  final String? icon;
  final Widget? iconWidget;
  final String text;
  const _Feature(this.icon, this.text) : iconWidget = null;
  const _Feature.widget(this.iconWidget, this.text) : icon = null;
}

class _CompactPlanRow extends StatelessWidget {
  final String name;
  final String price;
  final bool isCurrent;

  const _CompactPlanRow({
    required this.name,
    required this.price,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                context.tr('sub_current_plan'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              price,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final List<_Feature> features;
  final bool isRecommended;
  final bool isCurrent;
  final VoidCallback? onSubscribe;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.features,
    required this.isRecommended,
    required this.isCurrent,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isRecommended ? AppColors.primary : theme.colorScheme.outline,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              decoration: const BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg - 2),
                  topRight: Radius.circular(AppSpacing.radiusLg - 2),
                ),
              ),
              child: Text(
                context.tr('sub_recommended'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      price,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isRecommended
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Features
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        if (f.iconWidget != null)
                          SizedBox(width: 16, height: 16, child: f.iconWidget!)
                        else
                          QIcon(
                            f.icon!,
                            size: 16,
                            color: isRecommended
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            f.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Button
                if (isCurrent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      context.tr('sub_current_plan'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (onSubscribe != null)
                  AppButton(
                    label: context.tr('get_started'),
                    onPressed: onSubscribe,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
