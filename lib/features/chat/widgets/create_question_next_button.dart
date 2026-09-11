import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Sohbet sorusu olusturma — 1. adimin "Ileri" butonu.
class CreateQuestionNextButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onNext;

  const CreateQuestionNextButton({
    super.key,
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
            context.tr('next'),
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
