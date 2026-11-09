import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/form_mixin.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/features/auth/mixins/forgot_password_screen_mixin.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with FormMixin, LoadingMixin, ForgotPasswordScreenMixin {
  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.tr('reset_password'),
      body: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.tr('reset_password_desc'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              controller: emailCtrl,
              label: context.tr('email'),
              maxLength: AppConstants.emailMaxLength,
              keyboardType: TextInputType.emailAddress,
              validator: emailValidator,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: context.tr('send_reset_link'),
              isLoading: isLoading,
              onPressed: isLoading ? null : send,
            ),
          ],
        ),
      ),
    );
  }
}
