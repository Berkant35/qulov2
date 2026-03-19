import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/celebration_dialog.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

class PaywallBottomSheetContent extends ConsumerStatefulWidget {
  final String trigger;

  const PaywallBottomSheetContent({super.key, required this.trigger});

  static void show(WidgetRef ref, {required String trigger}) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.paywallView,
      params: {AnalyticsEvents.paramTrigger: trigger},
    );
    ref.read(navigationServiceProvider).showAppBottomSheet(
      CustomBottomSheet(
        name: 'paywall',
        maxHeightFactor: 0.92,
        builder: (_) => PaywallBottomSheetContent(trigger: trigger),
      ),
    );
  }

  @override
  ConsumerState<PaywallBottomSheetContent> createState() =>
      _PaywallBottomSheetContentState();
}

class _PaywallBottomSheetContentState
    extends ConsumerState<PaywallBottomSheetContent> {
  bool _isPurchasing = false;

  String _titleForTrigger(BuildContext context) {
    return switch (widget.trigger) {
      'undo_locked' => context.tr('paywall_title_undo'),
      'passport_locked' => context.tr('paywall_title_passport'),
      'question_limit' => context.tr('paywall_title_questions'),
      'swipe_limit' => context.tr('paywall_title_swipes'),
      _ => context.tr('paywall_title_general'),
    };
  }

  bool get _isPremiumOnlyTrigger => widget.trigger == 'passport_locked';

  Future<void> _handlePurchase(String plan) async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.subscriptionPurchaseStart,
      params: {
        AnalyticsEvents.paramTier: plan,
        AnalyticsEvents.paramTrigger: widget.trigger,
      },
    );

    final productId =
        plan == 'premium' ? 'qulopremiummonthly' : 'quloplusmonthly2';
    final success = await ref
        .read(subscriptionProvider.notifier)
        .purchaseByProductId(productId);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();

      ref.invalidate(subscriptionProvider);
      ref.invalidate(dailyStatsProvider);
      ref.invalidate(diamondProvider);

      final isPremium = plan == 'premium';
      final planName = isPremium
          ? context.tr('sub_plan_premium')
          : context.tr('sub_plan_plus');
      final bonus = isPremium ? 1500 : 500;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CelebrationDialog(
            planName: planName,
            diamondBonus: bonus,
            isPremium: isPremium,
          ),
        );
      }
    } else {
      setState(() => _isPurchasing = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('purchase_failed'))),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('sub_restore_done'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subAsync = ref.watch(subscriptionProvider);
    final currentPlan = subAsync.valueOrNull;
    final isFree = currentPlan?.isFree ?? true;
    final isPlus = currentPlan?.isPlus ?? false;
    final isPremium = currentPlan?.isPremium ?? false;

    return PopScope(
      canPop: !_isPurchasing,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              _titleForTrigger(context),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Comparison table
            _ComparisonTable(
              isFree: isFree,
              isPlus: isPlus,
              isPremium: isPremium,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Purchase buttons
            if (!isPlus && !_isPremiumOnlyTrigger)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppButton(
                  label: '${context.tr('sub_plan_plus')} — ${context.tr('sub_price_plus')}',
                  variant: AppButtonVariant.secondary,
                  isLoading: _isPurchasing,
                  onPressed: () => _handlePurchase('plus'),
                ),
              ),

            if (isPlus)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CurrentPlanBadge(
                  label: context.tr('sub_plan_plus'),
                ),
              ),

            if (!isPremium)
              AppButton(
                label: '${context.tr('sub_plan_premium')} — ${context.tr('sub_price_premium')}',
                isLoading: _isPurchasing,
                onPressed: () => _handlePurchase('premium'),
              ),

            if (isPremium)
              _CurrentPlanBadge(label: context.tr('sub_plan_premium')),

            const SizedBox(height: AppSpacing.lg),

            // Restore purchases
            TextButton(
              onPressed: _isPurchasing ? null : _handleRestore,
              child: Text(
                context.tr('sub_restore_purchases'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Current Plan Badge ───

class _CurrentPlanBadge extends StatelessWidget {
  final String label;
  const _CurrentPlanBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        '$label — ${context.tr('sub_current_plan')}',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Comparison Table ───

class _ComparisonTable extends StatelessWidget {
  final bool isFree;
  final bool isPlus;
  final bool isPremium;

  const _ComparisonTable({
    required this.isFree,
    required this.isPlus,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _HeaderRow(isFree: isFree, isPlus: isPlus, isPremium: isPremium),
          const Divider(height: 1),
          _FeatureRow(
            feature: context.tr('feature_daily_discovers'),
            free: '50',
            plus: context.tr('feature_unlimited'),
            premium: context.tr('feature_unlimited'),
          ),
          _FeatureRow(
            feature: context.tr('feature_question_slots'),
            free: '4',
            plus: '6',
            premium: '10',
          ),
          _FeatureRow(
            feature: context.tr('feature_undo'),
            free: null,
            plus: '3${context.tr('feature_per_day')}',
            premium: context.tr('feature_unlimited'),
          ),
          _FeatureRow(
            feature: context.tr('feature_monthly_diamonds'),
            free: null,
            plus: '500',
            premium: '1500',
            showDiamondIcon: true,
          ),
          _FeatureRow(
            feature: context.tr('feature_passport'),
            free: null,
            plus: null,
            premium: '✓',
          ),
          _FeatureRow(
            feature: context.tr('feature_no_ads'),
            free: null,
            plus: '✓',
            premium: '✓',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool isFree;
  final bool isPlus;
  final bool isPremium;

  const _HeaderRow({
    required this.isFree,
    required this.isPlus,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: SizedBox.shrink()),
          _PlanLabel(
            label: context.tr('sub_plan_free'),
            isCurrent: isFree,
            style: labelStyle,
          ),
          _PlanLabel(
            label: context.tr('sub_plan_plus'),
            isCurrent: isPlus,
            style: labelStyle,
          ),
          _PlanLabel(
            label: context.tr('sub_plan_premium'),
            isCurrent: isPremium,
            style: labelStyle,
            isPremiumColumn: true,
          ),
        ],
      ),
    );
  }
}

class _PlanLabel extends StatelessWidget {
  final String label;
  final bool isCurrent;
  final TextStyle? style;
  final bool isPremiumColumn;

  const _PlanLabel({
    required this.label,
    required this.isCurrent,
    this.style,
    this.isPremiumColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Text(
            label,
            style: style?.copyWith(
              color: isPremiumColumn ? AppColors.primary : null,
            ),
            textAlign: TextAlign.center,
          ),
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                context.tr('sub_current_plan'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  final String? free;
  final String? plus;
  final String? premium;
  final bool showDiamondIcon;
  final bool isLast;

  const _FeatureRow({
    required this.feature,
    required this.free,
    required this.plus,
    required this.premium,
    this.showDiamondIcon = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature, style: theme.textTheme.bodySmall),
          ),
          _CellValue(value: free, theme: theme),
          _CellValue(value: plus, theme: theme),
          _CellValue(
            value: premium,
            theme: theme,
            isPremiumColumn: true,
            showDiamondIcon: showDiamondIcon,
          ),
        ],
      ),
    );
  }
}

class _CellValue extends StatelessWidget {
  final String? value;
  final ThemeData theme;
  final bool isPremiumColumn;
  final bool showDiamondIcon;

  const _CellValue({
    required this.value,
    required this.theme,
    this.isPremiumColumn = false,
    this.showDiamondIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Center(
        child: value == null
            ? Icon(Icons.close, size: 14, color: AppColors.textHint)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDiamondIcon) ...[
                    const DiamondIcon.purple(size: 10),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      value!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPremiumColumn ? AppColors.primary : null,
                        fontWeight: value == '✓' ? FontWeight.bold : null,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
