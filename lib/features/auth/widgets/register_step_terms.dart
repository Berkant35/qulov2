import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class RegisterStepTerms extends StatelessWidget {
  final bool termsAccepted;
  final ValueChanged<bool?> onTermsChanged;
  final String? errorText;
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;

  const RegisterStepTerms({
    super.key,
    required this.termsAccepted,
    required this.onTermsChanged,
    this.errorText,
    this.isLoading = false,
    required this.onRegister,
    this.onTerms,
    this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('step_terms'),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: termsAccepted,
                onChanged: onTermsChanged,
                activeColor: context.appColors.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(text: '${l10n.get('accept_terms')} '),
                        TextSpan(
                          text: l10n.get('terms_of_service'),
                          style: TextStyle(
                            color: context.appColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = onTerms,
                        ),
                        TextSpan(text: ' ${l10n.get('and_word')} '),
                        TextSpan(
                          text: l10n.get('privacy_policy'),
                          style: TextStyle(
                            color: context.appColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = onPrivacy,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              child: Text(
                errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Spacer(),
          AppButton(
            label: l10n.get('register'),
            onPressed: onRegister,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
