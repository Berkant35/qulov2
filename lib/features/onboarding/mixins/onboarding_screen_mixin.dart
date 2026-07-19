import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/pending_languages_store.dart';
import 'package:qulo_v2/features/onboarding/screens/onboarding_screen.dart';
import 'package:qulo_v2/features/onboarding/widgets/premium_suggestion_sheet.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin OnboardingScreenMixin on ConsumerState<OnboardingScreen>,
    TickerProviderStateMixin<OnboardingScreen> {
  static const _prefKey = 'onboarding_v2_seen';
  static const _totalPages = 5;
  static const _pageNames = [
    'hook',
    'questions',
    'powers',
    'diamonds',
    'language',
  ];

  final _analytics = AnalyticsManager.instance;
  late final PageController pageController;
  late final AnimationController floatingController;

  int currentPage = 0;
  late List<String> selectedLanguages;
  double scrollOffset = 0.0;

  bool _mixinInitialized = false;

  void initMixin() {
    if (_mixinInitialized) return;
    _mixinInitialized = true;

    pageController = PageController()..addListener(_onScroll);
    floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final appLocale = Localizations.localeOf(context).languageCode;
    selectedLanguages = [
      AppConstants.supportedQuestionLocales.contains(appLocale)
          ? appLocale
          : 'tr',
    ];

    _analytics.logEvent(AnalyticsEvents.onboardingV2Start);
  }

  void disposeMixin() {
    pageController.dispose();
    floatingController.dispose();
  }

  void _onScroll() {
    if (pageController.hasClients) {
      setState(() {
        scrollOffset = pageController.page ?? 0.0;
      });
    }
  }

  void onPageChanged(int index) {
    setState(() => currentPage = index);
    _analytics.logEvent(AnalyticsEvents.onboardingV2PageView, params: {
      AnalyticsEvents.paramPageIndex: index,
      AnalyticsEvents.paramPageName: _pageNames[index],
    });
  }

  void onLanguageToggle(String locale) {
    setState(() {
      if (selectedLanguages.contains(locale)) {
        if (selectedLanguages.length > 1) {
          selectedLanguages.remove(locale);
        }
      } else {
        selectedLanguages.add(locale);
      }
    });
  }

  void onNext() {
    if (currentPage < _totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> onSkip() async {
    _analytics.logEvent(AnalyticsEvents.onboardingV2Skip, params: {
      AnalyticsEvents.paramFromPage: _pageNames[currentPage],
    });
    await _markSeen();
    if (!mounted) return;
    ref.read(navigationServiceProvider).go(RouteNames.discover);
  }

  Future<void> onStart() async {
    _analytics.logEvent(AnalyticsEvents.onboardingV2Complete);
    _analytics.logEvent(AnalyticsEvents.onboardingV2LanguagesSelected, params: {
      AnalyticsEvents.paramLanguages: selectedLanguages.join(','),
      AnalyticsEvents.paramLanguageCount: selectedLanguages.length,
    });
    await _markSeen();
    if (!mounted) return;
    // Auth oncesi: secimi local sakla, auth sonrasi app.dart flush eder.
    PendingLanguagesStore.write(selectedLanguages);
    _showPremiumSuggestion();
  }

  void _showPremiumSuggestion() {
    _analytics.logEvent(AnalyticsEvents.onboardingV2PremiumShown);
    ref.read(navigationServiceProvider).showAppBottomSheet(
      CustomBottomSheet(
        name: 'premium_suggestion',
        maxHeightFactor: 0.85,
        builder: (context) => const PremiumSuggestionSheet(),
      ),
    ).then((_) {
      if (mounted) {
        ref.read(navigationServiceProvider).go(RouteNames.discover);
      }
    });
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    await prefs.setBool('onboarding_questions_seen', true);
  }

  bool get isLastPage => currentPage == _totalPages - 1;
  int get totalPages => _totalPages;
}
