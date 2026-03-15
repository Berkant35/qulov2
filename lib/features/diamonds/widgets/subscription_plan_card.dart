import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/diamonds/models/plan_feature.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final String name;
  final String price;
  final List<PlanFeature> features;
  final bool isRecommended;
  final bool isCurrent;
  final VoidCallback? onSubscribe;

  const SubscriptionPlanCard({
    super.key,
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
