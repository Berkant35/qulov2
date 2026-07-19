import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/features/auth/mixins/social_auth_mixin.dart';
import 'package:qulo_v2/features/auth/screens/auth_landing_screen.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Social-first landing ekraninin lifecycle + analitik logic'i.
/// Screen sadece UI orchestration yapar, tum davranis burada toplanir.
mixin AuthLandingMixin
    on
        ConsumerState<AuthLandingScreen>,
        LoadingMixin<AuthLandingScreen>,
        SocialAuthMixin<AuthLandingScreen> {
  String? landingError;

  void initMixin() {
    FunnelEvents.logPreAuth(AnalyticsEvents.authLandingView);
  }

  void disposeMixin() {}

  @override
  void onSocialAuthError(String errorCode) {
    setState(() => landingError = context.l10n.errorMessage(errorCode));
  }

  void onGoogle() {
    FunnelEvents.logPreAuth(
      AnalyticsEvents.authLandingSocialSelected,
      params: {AnalyticsEvents.paramProvider: 'google'},
    );
    socialLogin('google');
  }

  void onApple() {
    FunnelEvents.logPreAuth(
      AnalyticsEvents.authLandingSocialSelected,
      params: {AnalyticsEvents.paramProvider: 'apple'},
    );
    socialLogin('apple');
  }

  void onEmail() {
    FunnelEvents.logPreAuth(AnalyticsEvents.authLandingEmailSelected);
    ref.read(navigationServiceProvider).push(RouteNames.login);
  }
}
