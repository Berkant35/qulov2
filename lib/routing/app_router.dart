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
import 'package:qulo_v2/features/passport/screens/map_picker_screen.dart';
import 'package:qulo_v2/features/settings/screens/settings_screen.dart';
import 'package:qulo_v2/features/profile/screens/edit_profile_screen.dart';
import 'package:qulo_v2/features/diamonds/screens/subscription_comparison_screen.dart';
import 'package:qulo_v2/features/notifications/screens/notifications_screen.dart';
import 'package:qulo_v2/features/questions/screens/question_create_screen.dart';
import 'package:qulo_v2/features/questions/screens/question_easy_mode_screen.dart';
import 'package:qulo_v2/features/questions/screens/question_analytics_screen.dart';
import 'package:qulo_v2/features/questions/screens/question_onboarding_screen.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/features/exchange/screens/exchange_screen.dart';
import 'package:qulo_v2/features/update/force_update_screen.dart';
import 'package:qulo_v2/features/update/maintenance_screen.dart';
import 'package:qulo_v2/features/profile_detail/screens/profile_detail_screen.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/chat/screens/create_chat_question_screen.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

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

      if (authState.status == AuthStatus.initial) return null;

      final isInviteRoute = state.matchedLocation.startsWith('/invite/');
      final isUpdateRoute = state.matchedLocation == '/force-update' || state.matchedLocation == '/maintenance';
      if (!isAuth && !isAuthRoute && !isInviteRoute && !isUpdateRoute) return '/auth/login';
      if (isAuth && isInviteRoute) return '/discover';
      if (isAuth && (isAuthRoute || isSplash)) return '/discover';

      return null;
    },
    routes: _routes,
  );
});
