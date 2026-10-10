import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

/// Seçilen cevabı onaylama butonu (gönderim sürerken yükleniyor).
class QuizConfirmButton extends StatelessWidget {
  final bool isSubmitting;
  final Future<void> Function() onSubmitAnswer;

  const QuizConfirmButton({
    super.key,
    required this.isSubmitting,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SafeTapButton(
        onTap: isSubmitting ? null : onSubmitAnswer,
        builder: (context, isLoading, onTap) => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            backgroundColor: context.appColors.primary,
          ),
          child: (isLoading || isSubmitting)
              ? AppLoadingWidget.small()
              : Text(
                  context.tr('quiz_confirm_answer'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
