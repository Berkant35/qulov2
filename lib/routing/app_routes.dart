part of 'app_router.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/',
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const SplashScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ),
  ),

  // Update
  GoRoute(
    path: '/force-update',
    name: RouteNames.forceUpdate,
    builder: (context, state) => const ForceUpdateScreen(),
  ),
  GoRoute(
    path: '/maintenance',
    name: RouteNames.maintenance,
    builder: (context, state) => const MaintenanceScreen(),
  ),

  // Invite deep link
  GoRoute(
    path: '/invite/:code',
    name: RouteNames.invite,
    redirect: (context, state) {
      final code = state.pathParameters['code'] ?? '';
      return '/auth/login/register?referralCode=$code';
    },
  ),

  // Auth
  GoRoute(
    path: '/auth/login',
    name: RouteNames.login,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const LoginScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ),
    routes: [
      GoRoute(
        path: 'register',
        name: RouteNames.register,
        builder: (context, state) {
          final referralCode = state.uri.queryParameters['referralCode'];
          return RegisterScreen(referralCode: referralCode);
        },
      ),
      GoRoute(
        path: 'forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
  ),

  // Onboarding
  GoRoute(
    path: '/onboarding',
    name: RouteNames.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),

  // Question Onboarding (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/questions/onboarding',
    name: RouteNames.questionOnboarding,
    builder: (context, state) => const QuestionOnboardingScreen(),
  ),

  // Map Picker (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/map-picker',
    name: RouteNames.mapPicker,
    builder: (context, state) => const MapPickerScreen(),
  ),

  // Quiz (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/quiz/:targetId',
    name: RouteNames.quiz,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: QuizScreen(targetId: state.pathParameters['targetId']!),
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    ),
  ),

  // Main shell (bottom nav)
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => _MainShell(shell: shell),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/discover',
          name: RouteNames.discover,
          builder: (context, state) => const DiscoverScreen(),
          routes: const [],
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/matches',
          name: RouteNames.matches,
          builder: (context, state) => const MatchesScreen(),
          routes: [
            GoRoute(
              path: 'chat/:matchId',
              name: RouteNames.chat,
              builder: (context, state) => ChatScreen(
                matchId: state.pathParameters['matchId']!,
              ),
            ),
          ],
        ),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/profile',
          name: RouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              name: RouteNames.editProfile,
              builder: (context, state) => const EditProfileScreen(),
            ),
            GoRoute(
              path: 'questions',
              name: RouteNames.questions,
              builder: (context, state) => const QuestionsScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: RouteNames.questionCreate,
                  builder: (context, state) {
                    final extra = state.extra;
                    QuestionModel? editQuestion;
                    if (extra is QuestionModel) {
                      editQuestion = extra;
                    } else if (extra is AiSuggestionModel) {
                      // Pre-fill from AI suggestion
                      editQuestion = null;
                    }
                    return QuestionCreateScreen(
                      editQuestion: editQuestion,
                      prefillSuggestion: extra is AiSuggestionModel ? extra : null,
                    );
                  },
                ),
                GoRoute(
                  path: 'easy-mode',
                  name: RouteNames.questionEasyMode,
                  builder: (context, state) => const QuestionEasyModeScreen(),
                ),
                GoRoute(
                  path: 'analytics',
                  name: RouteNames.questionAnalytics,
                  builder: (context, state) => const QuestionAnalyticsScreen(),
                ),
              ],
            ),
            GoRoute(
              path: 'diamonds',
              name: RouteNames.diamonds,
              builder: (context, state) => const DiamondsScreen(),
            ),
            GoRoute(
              path: 'passport',
              name: RouteNames.passport,
              builder: (context, state) => const PassportScreen(),
            ),
            GoRoute(
              path: 'exchange',
              name: RouteNames.exchange,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ExchangeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            ),
            GoRoute(
              path: 'subscription',
              name: RouteNames.subscription,
              builder: (context, state) => const SubscriptionComparisonScreen(),
            ),
            GoRoute(
              path: 'settings',
              name: RouteNames.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: 'notifications',
              name: RouteNames.notifications,
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ]),
    ],
  ),
];

class _MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  const _MainShell({required this.shell});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  @override
  void initState() {
    super.initState();
    _checkQuestionOnboarding();
  }

  Future<void> _checkQuestionOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_questions_seen') ?? false;
    if (!seen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(navigationServiceProvider).push(RouteNames.questionOnboarding);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).valueOrNull;
    final showProfileBadge = (user?.questionCount ?? 0) < AppConstants.minQuestions;

    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          NavigationBar(
            selectedIndex: widget.shell.currentIndex,
            onDestinationSelected: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: QIcon(QIcons.icCompass, size: 24),
                selectedIcon: QIcon(QIcons.icCompassFilled, size: 24),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: QIcon(QIcons.icHeart, size: 24),
                selectedIcon: QIcon(QIcons.icHeartFilled, size: 24),
                label: 'Matches',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: showProfileBadge,
                  smallSize: 10,
                  backgroundColor: AppColors.error,
                  child: QIcon(QIcons.icUser, size: 24),
                ),
                selectedIcon: Badge(
                  isLabelVisible: showProfileBadge,
                  smallSize: 10,
                  backgroundColor: AppColors.error,
                  child: QIcon(QIcons.icUserFilled, size: 24),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
