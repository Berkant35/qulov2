import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? completionText;
  final bool isComplete;
  final Widget child;

  const ProfileSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.completionText,
    this.isComplete = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: context.appColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: context.appColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (completionText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? context.appColors.secondary.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete)
                        Icon(Icons.check, color: context.appColors.secondary, size: 14),
                      if (isComplete) const SizedBox(width: 2),
                      Text(
                        completionText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isComplete
                              ? context.appColors.secondary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
