import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class SetupPhotoCard extends StatelessWidget {
  final bool isComplete;
  final bool isUploading;
  final VoidCallback onTap;

  const SetupPhotoCard({
    super.key,
    required this.isComplete,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isComplete ? colors.primarySurface : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isComplete ? colors.primary : theme.colorScheme.outline,
            width: 2,
          ),
          boxShadow: isComplete
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 28,
              color: isComplete
                  ? colors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      isComplete ? 'setup_photo_done' : 'setup_photo_title',
                    ),
                    style: theme.textTheme.titleLarge,
                  ),
                  if (!isComplete) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.tr('setup_photo_subtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isUploading)
              const AppLoadingWidget.small()
            else if (isComplete)
              Icon(Icons.check_circle, size: 24, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
