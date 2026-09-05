import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/form_mixin.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/features/auth/mixins/login_screen_mixin.dart';
import 'package:qulo_v2/features/auth/mixins/social_auth_mixin.dart';
import 'package:qulo_v2/features/auth/widgets/background_video.dart';
import 'package:qulo_v2/features/auth/widgets/login_header.dart';
import 'package:qulo_v2/features/auth/widgets/login_register_prompt.dart';
import 'package:qulo_v2/features/auth/widgets/login_version_label.dart';
import 'package:qulo_v2/features/auth/widgets/social_login_buttons.dart';
import 'package:qulo_v2/features/auth/widgets/staggered_column.dart';
import 'package:qulo_v2/routing/route_names.dart';

/*

DEBUG_EMAIL=tester_001@qulo.test
DEBUG_PASSWORD=Test1234!

* */
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with FormMixin, LoadingMixin, SocialAuthMixin, LoginScreenMixin {
  static final _gradientPainter = AppBackgroundPainter();

  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) Arka plan video + koyu overlay
            BackgroundVideo(
              assetPath: AppAssets.videoLoginBg,
              overlayOpacity: 0.75,
              onInitialized: onVideoInitialized,
              onFailed: onVideoFailed,
            ),

            // 2) Gradient daireler (AppScaffold ile paylaşımlı)
            Positioned.fill(
              child: CustomPaint(
                painter: _gradientPainter,
              ),
            ),

            // 3) Form içeriği
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.pagePadding),
                        child: Form(
                          key: formKey,
                          child: StaggeredColumn(
                            key: staggeredKey,
                            autoForwardAfter: AppConstants.loginFormRevealFallback,
                            children: [
                              const SizedBox(height: AppSpacing.xxxl),
                              const LoginHeader(),
                              const SizedBox(height: AppSpacing.xxxl),
                              AppTextField(
                                controller: emailCtrl,
                                label: context.tr('email'),
                                maxLength: 254,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: emailValidator,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppTextField(
                                controller: passwordCtrl,
                                label: context.tr('password'),
                                maxLength: 128,
                                obscureText: obscure,
                                textInputAction: TextInputAction.done,
                                validator: passwordValidator,
                                onFieldSubmitted: (_) => login(),
                                errorText: loginError,
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: toggleObscure,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => ref
                                      .read(navigationServiceProvider)
                                      .push(RouteNames.forgotPassword),
                                  child: Text(context.tr('forgot_password')),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton(
                                label: context.tr('login'),
                                isLoading: isLoading,
                                onPressed: isLoading ? null : login,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              SocialLoginButtons(
                                isLoading: isLoading,
                                onGooglePressed: () => socialLogin('google'),
                                onApplePressed: () => socialLogin('apple'),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              LoginRegisterPrompt(
                                onRegisterTap: () => ref
                                    .read(navigationServiceProvider)
                                    .push(RouteNames.register),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Dil değiştirme butonu — sağ üst köşe
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: IconButton(
                      icon: const Icon(Icons.language),
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      tooltip: context.tr('language'),
                      onPressed: showLanguagePicker,
                    ),
                  ),
                  // Powered by + sürüm — alt orta
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.sm,
                    child: LoginVersionLabel(appVersion: appVersion),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
