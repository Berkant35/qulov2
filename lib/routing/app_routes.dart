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

  // Auth states
  GoRoute(
    path: '/banned',
    name: RouteNames.banned,
    builder: (context, state) => const BannedScreen(),
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
      return '/profile/diamonds?referralCode=$code';
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
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: 'forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
  ),

  // Profile Completion (root navigator — social login users without age)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/profile-completion',
    name: RouteNames.profileCompletion,
    builder: (context, state) => const ProfileCompletionScreen(),
  ),

  // Onboarding (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/onboarding',
    name: RouteNames.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),

  // Profile Setup Gate (root navigator — full screen, no bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/profile-setup',
    name: RouteNames.profileSetup,
    builder: (context, state) => const ProfileSetupScreen(),
  ),

  // Map Confirm (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/map-confirm',
    name: RouteNames.mapConfirm,
    builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return MapConfirmScreen(
        cityName: extra['cityName'] as String,
        country: extra['country'] as String,
        flag: extra['flag'] as String,
        lat: extra['lat'] as double,
        lng: extra['lng'] as double,
      );
    },
  ),

  // Quiz (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/quiz/:targetId',
    name: RouteNames.quiz,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: QuizScreen(
        targetId: state.pathParameters['targetId']!,
        targetPhotoUrl: state.extra is String ? state.extra as String : null,
      ),
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

  // Legal (root navigator — full screen, no bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/terms',
    name: RouteNames.terms,
    builder: (context, state) {
      final locale = AppLocalizations.of(context).locale.languageCode;
      return LegalWebViewScreen(
        title: AppLocalizations.of(context).get('terms_of_service'),
        url: '${Env.legalBaseUrl}/$locale/terms/',
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/privacy-policy',
    name: RouteNames.privacyPolicy,
    builder: (context, state) {
      final locale = AppLocalizations.of(context).locale.languageCode;
      return LegalWebViewScreen(
        title: AppLocalizations.of(context).get('privacy_policy'),
        url: '${Env.legalBaseUrl}/$locale/privacy-policy/',
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/help',
    name: RouteNames.help,
    builder: (context, state) {
      final locale = AppLocalizations.of(context).locale.languageCode;
      final url = state.extra is String
          ? state.extra as String
          : '${Env.legalBaseUrl}/$locale/help/';
      return LegalWebViewScreen(
        title: AppLocalizations.of(context).get('help_support'),
        url: url,
      );
    },
  ),

  // Chat (root navigator — full screen, no bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/chat/:matchId',
    name: RouteNames.chat,
    builder: (context, state) => ChatScreen(
      matchId: state.pathParameters['matchId']!,
    ),
  ),

  // Create Chat Question (root navigator — full screen stepper)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/chat/:matchId/create-question',
    name: RouteNames.createChatQuestion,
    builder: (context, state) => CreateChatQuestionScreen(
      matchId: state.pathParameters['matchId']!,
    ),
  ),

  // Solve Chat Question (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/chat-question/:questionId/solve',
    name: RouteNames.solveChatQuestion,
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return CustomTransitionPage(
        key: state.pageKey,
        child: SolveChatQuestionScreen(
          question: extra['question'] as ChatQuestionModel,
          matchId: extra['matchId'] as String,
        ),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
      );
    },
  ),

  // Profile Detail (root navigator — full screen over bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/profile-detail/:userId',
    name: RouteNames.profileDetail,
    builder: (context, state) => ProfileDetailScreen(
      userId: state.pathParameters['userId']!,
      args: state.extra is ProfileDetailArgs ? state.extra as ProfileDetailArgs : null,
    ),
  ),

  // Profile Preview (root navigator — full screen, no bottom nav)
  GoRoute(
    parentNavigatorKey: rootNavigatorKey,
    path: '/profile/preview',
    name: RouteNames.profilePreview,
    builder: (context, state) {
      final source = state.extra is String ? state.extra as String : 'profile_screen';
      return ProfilePreviewScreen(source: source);
    },
  ),

  // Main shell (bottom nav)
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => _MainShell(shell: shell),
    branches: [
      StatefulShellBranch(observers: [RouteChangeObserver()], routes: [
        GoRoute(
          path: '/discover',
          name: RouteNames.discover,
          builder: (context, state) => const DiscoverScreen(),
          routes: const [],
        ),
      ]),
      StatefulShellBranch(observers: [RouteChangeObserver()], routes: [
        GoRoute(
          path: '/matches',
          name: RouteNames.matches,
          builder: (context, state) => const MatchesScreen(),
        ),
      ]),
      StatefulShellBranch(observers: [RouteChangeObserver()], routes: [
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
              builder: (context, state) {
                final referralCode = state.uri.queryParameters['referralCode'];
                return DiamondsScreen(referralCode: referralCode);
              },
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
              path: 'performance',
              name: RouteNames.performance,
              builder: (context, state) => const PerformanceDashboardScreen(),
            ),
            GoRoute(
              path: 'settings',
              name: RouteNames.settings,
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'blocked-users',
                  name: RouteNames.blockedUsers,
                  builder: (context, state) => const BlockedUsersScreen(),
                ),
                GoRoute(
                  path: 'my-tickets',
                  name: RouteNames.myTickets,
                  builder: (context, state) => const MyTicketsScreen(),
                ),
              ],
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
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_v2_seen') ?? false;
    final oldSeen = prefs.getBool('onboarding_questions_seen') ?? false;
    if (!seen && !oldSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(navigationServiceProvider).push(RouteNames.onboarding);
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
            onDestinationSelected: (i) {
              if (i == 0 && widget.shell.currentIndex != 0) {
                ref.read(discoverProvider.notifier).loadCards();
              }
              widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex);
            },
            destinations: [
              NavigationDestination(
                icon: QIcon(QIcons.icCompass, size: 24),
                selectedIcon: QIcon(QIcons.icCompassFilled, size: 24),
                label: context.tr('discover'),
              ),
              NavigationDestination(
                icon: AppIcon(QIcons.heart, filled: false, size: 24),
                selectedIcon: AppIcon(QIcons.heart, filled: true, size: 24),
                label: context.tr('matches'),
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: showProfileBadge,
                  smallSize: 10,
                  backgroundColor: AppColors.error,
                  child: AppIcon(QIcons.userRounded, filled: false, size: 24),
                ),
                selectedIcon: Badge(
                  isLabelVisible: showProfileBadge,
                  smallSize: 10,
                  backgroundColor: AppColors.error,
                  child: AppIcon(QIcons.userRounded, filled: true, size: 24),
                ),
                label: context.tr('profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
