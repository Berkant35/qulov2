import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class CelebrationDialog extends StatelessWidget {
  final String planName;
  final int diamondBonus;
  final bool isPremium;

  const CelebrationDialog({
    super.key,
    required this.planName,
    required this.diamondBonus,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: context.appColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient plan badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: context.appColors.purpleGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                planName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              isPremium
                  ? context.tr('celebration_title_premium')
                  : context.tr('celebration_title_plus'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Diamond bonus
            if (diamondBonus > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DiamondIcon.purple(size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    isPremium
                        ? context.tr('celebration_diamonds_premium')
                        : context.tr('celebration_diamonds_plus'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: context.appColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('celebration_diamonds_desc'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Button
            AppButton(
              label: context.tr('celebration_button'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
