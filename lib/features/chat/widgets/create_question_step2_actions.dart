import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

/// Sohbet sorusu olusturma — 2. adim: Gonder + (Geri, Taslak Kaydet).
class CreateQuestionStep2Actions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;

  const CreateQuestionStep2Actions({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: !isLoading
                  ? context.appColors.primaryButtonGradient
                  : null,
              color: isLoading
                  ? context.appColors.textHint.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: MaterialButton(
              onPressed: !isLoading ? onSubmit : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: isLoading
                  ? const AppLoadingWidget.small()
                  : Text(
                      context.tr('chat_question_send'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Row with Back + Save Draft
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: !isLoading ? onBack : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.appColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    context.tr('chat_question_back'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: !isLoading ? onSaveDraft : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.appColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    context.tr('chat_question_save_draft'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
