import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';

class RegisterStepTerms extends StatelessWidget {
  final bool termsAccepted;
  final ValueChanged<bool?> onTermsChanged;
  final String? errorText;
  final bool isLoading;
  final VoidCallback onRegister;
  final ValueChanged<String>? onOpenUrl;
  // Referral code
  final TextEditingController? referralCodeCtrl;
  final bool referralExpanded;
  final VoidCallback? onToggleReferral;
  final VoidCallback? onValidateReferral;
  final bool validatingReferral;
  final String? referralValidName;
  final String? referralError;

  const RegisterStepTerms({
    super.key,
    required this.termsAccepted,
    required this.onTermsChanged,
    this.errorText,
    this.isLoading = false,
    required this.onRegister,
    this.onOpenUrl,
    this.referralCodeCtrl,
    this.referralExpanded = false,
    this.onToggleReferral,
    this.onValidateReferral,
    this.validatingReferral = false,
    this.referralValidName,
    this.referralError,
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
                activeColor: AppColors.primary,
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
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => onOpenUrl?.call('https://qulo.app/terms'),
                        ),
                        TextSpan(text: ' ${l10n.get('and_word')} '),
                        TextSpan(
                          text: l10n.get('privacy_policy'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => onOpenUrl?.call('https://qulo.app/privacy'),
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
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),

          // ─── Referral Code (optional expandable) ───
          if (referralCodeCtrl != null) ...[
            GestureDetector(
              onTap: onToggleReferral,
              child: Row(
                children: [
                  Icon(
                    referralExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.get('referral_have_code'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (referralExpanded) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: referralCodeCtrl!,
                label: l10n.get('referral_code_hint'),
                errorText: referralError,
                prefixIcon: const Icon(Icons.card_giftcard_outlined),
                suffixIcon: validatingReferral
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: AppLoadingWidget.small(),
                      )
                    : null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onValidateReferral?.call(),
              ),
              if (referralValidName != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  child: Text(
                    '${l10n.get('referral_code_valid')}$referralValidName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ],

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
