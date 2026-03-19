import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/questions/widgets/onboarding_slide.dart';
import 'package:qulo_v2/features/questions/widgets/onboarding_language_slide.dart';
import 'package:qulo_v2/providers/user_languages_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class QuestionOnboardingScreen extends ConsumerStatefulWidget {
  const QuestionOnboardingScreen({super.key});

  @override
  ConsumerState<QuestionOnboardingScreen> createState() =>
      _QuestionOnboardingScreenState();
}

class _QuestionOnboardingScreenState
    extends ConsumerState<QuestionOnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  late List<String> _selectedLanguages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appLocale = Localizations.localeOf(context).languageCode;
    _selectedLanguages = [
      AppConstants.supportedQuestionLocales.contains(appLocale)
          ? appLocale
          : 'tr',
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_questions_seen', true);
  }

  Future<void> _onStart() async {
    await _markSeen();
    if (!mounted) return;
    ref.read(userLanguagesProvider.notifier).save(_selectedLanguages);
    ref.read(navigationServiceProvider).go(RouteNames.questions);
  }

  Future<void> _onSkip() async {
    await _markSeen();
    if (!mounted) return;
    final nav = ref.read(navigationServiceProvider);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.go(RouteNames.discover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Page View ───
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: [
                    OnboardingSlide(
                      iconPath: QIcons.icHelpCircle,
                      title: context.tr('onboarding_questions_slide1_title'),
                      description:
                          context.tr('onboarding_questions_slide1_desc'),
                      iconColor: AppColors.primary,
                    ),
                    OnboardingSlide(
                      iconPath: QIcons.icWand,
                      title: context.tr('onboarding_questions_slide2_title'),
                      description:
                          context.tr('onboarding_questions_slide2_desc'),
                      iconColor: AppColors.primary,
                    ),
                    OnboardingSlide(
                      iconPath: QIcons.icGem,
                      title: context.tr('onboarding_questions_slide3_title'),
                      description:
                          context.tr('onboarding_questions_slide3_desc'),
                      iconColor: AppColors.secondary,
                    ),
                    // Slide 4: Language selection
                    OnboardingLanguageSlide(
                      selectedLanguages: _selectedLanguages,
                      onToggle: (locale) {
                        setState(() {
                          if (_selectedLanguages.contains(locale)) {
                            if (_selectedLanguages.length > 1) {
                              _selectedLanguages.remove(locale);
                            }
                          } else {
                            _selectedLanguages.add(locale);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ─── Dot Indicator ───
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                    );
                  }),
                ),
              ),

              // ─── Buttons ───
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    if (_currentPage == 3)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _onStart,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                          ),
                          child: Text(
                            context.tr('onboarding_questions_start'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        context.tr('onboarding_questions_later'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
