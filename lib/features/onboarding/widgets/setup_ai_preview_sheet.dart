import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class SetupAiPreviewSheet extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final VoidCallback onAssign;
  final VoidCallback onRegenerate;
  final VoidCallback onSkip; // "Sen seç" — fallback to quick-assign upstream
  final bool isProcessing;

  const SetupAiPreviewSheet({
    super.key,
    required this.suggestions,
    required this.onAssign,
    required this.onRegenerate,
    required this.onSkip,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              context.tr('preview_sheet_title'),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Suggestion cards
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (s['question_text'] ?? '') as String,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          (s['answers'] as List?)?.join(' · ') ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: AppSpacing.lg),

            // Assign CTA
            AppButton(
              label: context.tr('preview_sheet_assign_cta'),
              onPressed: isProcessing ? null : onAssign,
              fullWidth: true,
              isLoading: isProcessing,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Regenerate
            AppButton(
              label: context.tr('preview_sheet_regen_cta'),
              onPressed: isProcessing ? null : onRegenerate,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Skip link
            TextButton(
              onPressed: isProcessing ? null : onSkip,
              child: Text(
                context.tr('preview_sheet_skip_link'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
