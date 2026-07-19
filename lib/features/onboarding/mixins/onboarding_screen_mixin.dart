import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/core/services/pending_languages_store.dart';
import 'package:qulo_v2/features/onboarding/screens/onboarding_screen.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';

mixin OnboardingScreenMixin on ConsumerState<OnboardingScreen>,
    TickerProviderStateMixin<OnboardingScreen> {
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
    FunnelEvents.logPreAuth(AnalyticsEvents.onboardingV2PageView, params: {
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
    FunnelEvents.logPreAuth(AnalyticsEvents.onboardingV2Skip, params: {
      AnalyticsEvents.paramFromPage: _pageNames[currentPage],
    });
    await _markSeen();
  }

  Future<void> onStart() async {
    FunnelEvents.logPreAuth(AnalyticsEvents.onboardingV2Complete);
    FunnelEvents.logPreAuth(AnalyticsEvents.onboardingV2LanguagesSelected, params: {
      AnalyticsEvents.paramLanguages: selectedLanguages.join(','),
      AnalyticsEvents.paramLanguageCount: selectedLanguages.length,
    });
    // Auth oncesi: secimi local sakla, auth sonrasi app.dart flush eder.
    // markSeen'den ONCE ve await'li olmali: markSeen notifier state'ini
    // senkron degistirir → router refresh → /onboarding'den redirect →
    // widget dispose olabilir → !mounted → write atlanir → dil secimi kaybolur.
    await PendingLanguagesStore.write(selectedLanguages);
    await _markSeen();
  }

  Future<void> _markSeen() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
  }

  bool get isLastPage => currentPage == _totalPages - 1;
  int get totalPages => _totalPages;
}
