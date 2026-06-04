import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/features/splash/splash_screen.dart';
import 'package:qulo_v2/features/auth/screens/login_screen.dart';
import 'package:qulo_v2/features/auth/screens/register_screen.dart';
import 'package:qulo_v2/features/auth/screens/forgot_password_screen.dart';
import 'package:qulo_v2/features/onboarding/screens/onboarding_screen.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/features/chat/screens/matches_screen.dart';
import 'package:qulo_v2/features/chat/screens/chat_screen.dart';
import 'package:qulo_v2/features/profile/screens/profile_screen.dart';
import 'package:qulo_v2/features/profile/screens/questions_screen.dart';
import 'package:qulo_v2/features/diamonds/screens/diamonds_screen.dart';
import 'package:qulo_v2/features/passport/screens/passport_screen.dart';
import 'package:qulo_v2/features/passport/screens/map_confirm_screen.dart';
import 'package:qulo_v2/features/settings/screens/settings_screen.dart';
import 'package:qulo_v2/features/profile/screens/edit_profile_screen.dart';
import 'package:qulo_v2/features/diamonds/screens/subscription_comparison_screen.dart';
import 'package:qulo_v2/features/notifications/screens/notifications_screen.dart';
import 'package:qulo_v2/features/questions/screens/question_create_screen.dart';
import 'package:qulo_v2/features/questions/screens/question_easy_mode_screen.dart';
import 'package:qulo_v2/features/questions/screens/question_analytics_screen.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/features/exchange/screens/exchange_screen.dart';
import 'package:qulo_v2/features/update/force_update_screen.dart';
import 'package:qulo_v2/features/update/maintenance_screen.dart';
import 'package:qulo_v2/features/profile_detail/screens/profile_detail_screen.dart';
import 'package:qulo_v2/features/profile/screens/profile_preview_screen.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/chat/screens/create_chat_question_screen.dart';
import 'package:qulo_v2/features/chat/screens/solve_chat_question_screen.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/performance/screens/performance_dashboard_screen.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/deep_link_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/legal/screens/legal_web_view_screen.dart';
import 'package:qulo_v2/features/settings/screens/blocked_users_screen.dart';
import 'package:qulo_v2/features/settings/screens/my_tickets_screen.dart';
import 'package:qulo_v2/features/auth/screens/banned_screen.dart';
import 'package:qulo_v2/features/auth/screens/profile_completion_screen.dart';
import 'package:qulo_v2/core/config/env.dart';

part 'app_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthNotifierListenable(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/';

      // 1. Auth yukleniyor — bekle
      if (authState.status == AuthStatus.initial) return null;

      // 1b. Hesap banlı — banned ekranına yönlendir
      if (authState.status == AuthStatus.banned) {
        if (state.matchedLocation == '/banned') return null;
        return '/banned';
      }

      // 2. Update/maintenance route'lari — her zaman izin ver
      final isUpdateRoute = state.matchedLocation == '/force-update' ||
          state.matchedLocation == '/maintenance';
      if (isUpdateRoute) return null;

      // 3. Invite route — mevcut logic
      final isInviteRoute = state.matchedLocation.startsWith('/invite/');
      if (isAuth && isInviteRoute) {
        final code = state.pathParameters['code'] ?? '';
        return '/profile/diamonds?referralCode=$code';
      }

      // 4. Legal route'lar — her zaman izin ver (kayit ekranindan erisilebilir)
      final isLegalRoute = state.matchedLocation == '/terms' ||
          state.matchedLocation == '/privacy-policy' ||
          state.matchedLocation == '/help';
      if (isLegalRoute) return null;

      // Non-auth user clicking invite link → store as pending, redirect to login
      if (!isAuth && isInviteRoute) {
        final code = state.pathParameters['code'] ?? '';
        if (code.isNotEmpty) {
          ref.read(pendingDeepLinkProvider.notifier).state =
              '/profile/diamonds?referralCode=$code';
        }
        return '/auth/login';
      }

      // 5. Auth degil → login'e yonlendir (auth, update haric)
      if (!isAuth && !isAuthRoute && !isUpdateRoute) {
        return '/auth/login';
      }

      // 5. Pending deep link replay — login sonrasi deferred link
      final pendingLink = ref.read(pendingDeepLinkProvider);
      if (isAuth && pendingLink != null) {
        ref.read(pendingDeepLinkProvider.notifier).state = null;
        ref.read(analyticsManagerProvider).logDeepLinkReplayed(pendingLink);
        return pendingLink;
      }

      // 6. Profile completion check — age null means social login user hasn't completed profile
      if (isAuth && state.matchedLocation != '/profile-completion') {
        final user = ref.read(userProvider).value;
        if (user != null && user.age == null) {
          return '/profile-completion';
        }
      }

      // Already on profile-completion but profile is done → go to discover
      if (isAuth && state.matchedLocation == '/profile-completion') {
        final user = ref.read(userProvider).value;
        if (user != null && user.age != null) {
          return '/discover';
        }
        return null;
      }

      // 6. Auth + auth route veya splash → discover'a yonlendir
      if (isAuth && (isAuthRoute || isSplash)) return '/discover';

      return null;
    },
    routes: _routes,
  );
});
