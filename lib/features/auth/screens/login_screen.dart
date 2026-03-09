import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/mixins/form_mixin.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with FormMixin, LoadingMixin {
  final _emailCtrl = TextEditingController(
    text: kDebugMode ? 'berkantC93@gmail.com' : null,
  );
  final _passwordCtrl = TextEditingController(
    text: kDebugMode ? 'dad.153hb' : null,
  );
  bool _obscure = true;
  String? _loginError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() => withLoading(() async {
        setState(() => _loginError = null);
        if (!validateForm()) return;
        final result = await ref.read(authProvider.notifier).login(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            );
        result.when(
          success: (_) {},
          failure: (f) {
            final errorCode = switch (f) {
              ServerFailure(:final code) => code,
              NetworkFailure() => 'NETWORK_ERROR',
              TimeoutFailure() => 'TIMEOUT',
              _ => 'UNKNOWN',
            };
            setState(() => _loginError = context.l10n.errorMessage(errorCode));
          },
        );
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Center(
                child: SvgPicture.asset(
                  AppAssets.logoSvg,
                  width: AppSizes.logoMd,
                  height: AppSizes.logoMd,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('app_name'),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('welcome_back'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppTextField(
                controller: _emailCtrl,
                label: context.tr('email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: emailValidator,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _passwordCtrl,
                label: context.tr('password'),
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                validator: passwordValidator,
                onFieldSubmitted: (_) => _login(),
                errorText: _loginError,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      ref.read(navigationServiceProvider).push(RouteNames.forgotPassword),
                  child: Text(context.tr('forgot_password')),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: context.tr('login'),
                isLoading: isLoading,
                onPressed: isLoading ? null : _login,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.tr('no_account'),
                      style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () =>
                        ref.read(navigationServiceProvider).push(RouteNames.register),
                    child: Text(context.tr('register')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
