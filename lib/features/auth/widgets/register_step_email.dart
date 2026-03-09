import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';

class RegisterStepEmail extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final String? emailError;
  final String? passwordError;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onContinue;

  const RegisterStepEmail({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    this.emailError,
    this.passwordError,
    this.obscurePassword = true,
    required this.onToggleObscure,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('step_email'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: emailCtrl,
            label: l10n.get('email'),
            errorText: emailError,
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: passwordCtrl,
            label: l10n.get('password'),
            errorText: passwordError,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleObscure,
            ),
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onContinue(),
          ),
          const Spacer(),
          AppButton(
            label: l10n.get('continue_btn'),
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
