import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/auth/mixins/auth_landing_mixin.dart';
import 'package:qulo_v2/features/auth/mixins/social_auth_mixin.dart';
import 'package:qulo_v2/features/auth/widgets/auth_landing_body.dart';
import 'package:qulo_v2/features/auth/widgets/social_login_buttons.dart';

/// Social-first landing ekrani — onboarding sonrasi auth olmayan
/// kullanicinin ilk gordugu ekran. Google/Apple/e-posta uc yolu sunar.
class AuthLandingScreen extends ConsumerStatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  ConsumerState<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends ConsumerState<AuthLandingScreen>
    with
        LoadingMixin<AuthLandingScreen>,
        SocialAuthMixin<AuthLandingScreen>,
        AuthLandingMixin {
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
    return AppScaffold(
      body: AuthLandingBody(
        title: context.tr('auth_landing_title'),
        subtitle: context.tr('auth_landing_subtitle'),
        continueEmailLabel: context.tr('auth_landing_continue_email'),
        error: landingError,
        socialButtons: SocialLoginButtons(
          isLoading: isLoading,
          onGooglePressed: onGoogle,
          onApplePressed: onApple,
        ),
        onEmail: onEmail,
      ),
    );
  }
}
