import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/core/services/pending_languages_store.dart';
import 'package:qulo_v2/features/onboarding/screens/onboarding_screen.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

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

  /// Desteklenen 16 dilin tumunu sirasiyla secer ("select all" aksiyonu).
  void selectAllLanguages() {
    setState(() {
      selectedLanguages = List.of(AppConstants.supportedQuestionLocales);
    });
  }

  /// Secimi tek dile sifirlar — initMixin'deki ile ayni kural (app dili
  /// destekleniyorsa o, degilse 'tr').
  void resetLanguages() {
    final appLocale = Localizations.localeOf(context).languageCode;
    setState(() {
      selectedLanguages = [
        AppConstants.supportedQuestionLocales.contains(appLocale)
            ? appLocale
            : 'tr',
      ];
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
    _goToLanding();
  }

  Future<void> onStart() async {
    FunnelEvents.logPreAuth(AnalyticsEvents.onboardingV2Complete);
    FunnelEvents.logPreAuth(AnalyticsEvents.onboardingV2LanguagesSelected, params: {
      AnalyticsEvents.paramLanguages: selectedLanguages.join(','),
      AnalyticsEvents.paramLanguageCount: selectedLanguages.length,
    });
    // Auth oncesi: secimi local sakla (auth sonrasi app.dart flush eder).
    // markSeen'den ONCE ve await'li: markSeen dilleri persist etmeden onceki
    // olasi dispose'da secimin kaybolmamasi icin.
    await PendingLanguagesStore.write(selectedLanguages);
    await _markSeen();
    _goToLanding();
  }

  /// Carousel bittikten sonra deterministik olarak landing'e gecer. Redirect
  /// guard'lari erisimi KAPILAMAK icindir (auth olmayan kullanici carousel'i
  /// atlamasin); ileri-gecis icin explicit navigasyon kullaniriz — router
  /// refresh'ine guvenmek kirilgan. Hedef landing ile redirect hedefi ayni
  /// oldugundan cift-navigasyon zararsiz. Widget dispose olduysa (redirect
  /// zaten tasidiysa) atlanir.
  void _goToLanding() {
    if (!mounted) return;
    ref.read(navigationServiceProvider).go(RouteNames.authLanding);
  }

  Future<void> _markSeen() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
  }

  bool get isLastPage => currentPage == _totalPages - 1;
  int get totalPages => _totalPages;

  /// 16 dilin tumu secili mi — "select all" / "reset" buton etiketini belirler.
  bool get allLanguagesSelected =>
      selectedLanguages.length == AppConstants.supportedQuestionLocales.length;
}
