import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class CreateQuestionBottomButtons extends StatelessWidget {
  final int currentStep;
  final bool isLoading;
  final bool isStep1Valid;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;

  const CreateQuestionBottomButtons({
    super.key,
    required this.currentStep,
    required this.isLoading,
    required this.isStep1Valid,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        top: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      child: currentStep == 0
          ? _Step1NextButton(
              isEnabled: isStep1Valid && !isLoading,
              onNext: onNext,
            )
          : _Step2ActionButtons(
              isLoading: isLoading,
              onSubmit: onSubmit,
              onBack: onBack,
              onSaveDraft: onSaveDraft,
            ),
    );
  }
}

class _Step1NextButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onNext;

  const _Step1NextButton({
    required this.isEnabled,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient:
              isEnabled ? context.appColors.primaryButtonGradient : null,
          color: isEnabled
              ? null
              : context.appColors.textHint.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: MaterialButton(
          onPressed: isEnabled ? onNext : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            'Ileri',
            style: theme.textTheme.titleSmall?.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Step2ActionButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;

  const _Step2ActionButtons({
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
                      'Gonder',
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
                    'Geri',
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
                    'Taslak Kaydet',
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
