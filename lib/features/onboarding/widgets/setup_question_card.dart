import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

/// Loader policy: only Quick Assign shows `isLoading` because it performs a
/// network call inline. Magic Fill opens a bottom sheet immediately (no
/// network), and Manual Create pushes a route — a spinner on either would be
/// misleading. All three CTAs still disable via `isProcessing` so the user
/// cannot double-tap into a different flow mid-async.
class SetupQuestionCard extends StatelessWidget {
  final bool isComplete;
  final bool isProcessing;
  final VoidCallback onMagicFill;
  final VoidCallback onQuickAssign;
  final VoidCallback onManualCreate;
  final VoidCallback onEdit;

  const SetupQuestionCard({
    super.key,
    required this.isComplete,
    required this.isProcessing,
    required this.onMagicFill,
    required this.onQuickAssign,
    required this.onManualCreate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return AnimatedContainer(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz_outlined,
                size: 28,
                color: isComplete
                    ? colors.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.tr(
                    isComplete ? 'setup_question_done' : 'setup_question_title',
                  ),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (isComplete)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr('setup_question_subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.tr('setup_question_magic_cta'),
              onPressed: isProcessing ? null : onMagicFill,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: context.tr('setup_question_quick_cta'),
              onPressed: isProcessing ? null : onQuickAssign,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              isLoading: isProcessing,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: isProcessing ? null : onManualCreate,
                child: Text(
                  context.tr('setup_question_manual_cta'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
