import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';

class MilestoneCelebrationSheet extends StatelessWidget {
  final int milestone;
  final int reward;

  const MilestoneCelebrationSheet({
    super.key,
    required this.milestone,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.textHint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Celebration icon
          Icon(
            Icons.celebration,
            color: context.appColors.primary,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Headline
          Text(
            'Tebrikler!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Body text
          Text(
            'Profilini %$milestone tamamladın!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.appColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Diamond reward row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DiamondIcon.purple(size: 32),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '+$reward',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            'Mor elmas kazandın!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),

          // Extra section for 100% milestone
          if (milestone == 100) ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: context.appColors.secondary),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                color: context.appColors.secondarySurface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt,
                    color: context.appColors.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      '24 saatlik ücretsiz boost kazandın!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
