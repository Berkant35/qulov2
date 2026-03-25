import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/questions/screens/question_onboarding_screen.dart';
import 'package:qulo_v2/providers/user_languages_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin QuestionOnboardingScreenMixin on ConsumerState<QuestionOnboardingScreen> {
  final pageController = PageController();
  int currentPage = 0;
  late List<String> selectedLanguages;

  void initMixin() {
    final appLocale = Localizations.localeOf(context).languageCode;
    selectedLanguages = [
      AppConstants.supportedQuestionLocales.contains(appLocale)
          ? appLocale
          : 'tr',
    ];
  }

  void disposeMixin() {
    pageController.dispose();
  }

  void onPageChanged(int index) {
    setState(() => currentPage = index);
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

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_questions_seen', true);
  }

  Future<void> onStart() async {
    await _markSeen();
    if (!mounted) return;
    ref.read(userLanguagesProvider.notifier).save(selectedLanguages);
    ref.read(navigationServiceProvider).go(RouteNames.questions);
  }

  Future<void> onSkip() async {
    await _markSeen();
    if (!mounted) return;
    final nav = ref.read(navigationServiceProvider);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.go(RouteNames.discover);
    }
  }
}
