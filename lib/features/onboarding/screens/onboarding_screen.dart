import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/onboarding/mixins/onboarding_screen_mixin.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_bottom_bar.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_diamonds_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_hook_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_language_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_powers_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_questions_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/parallax_background.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin, OnboardingScreenMixin {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.onboardingGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Parallax background
              ParallaxBackground(
                scrollOffset: scrollOffset,
                floatingAnimation: floatingController,
              ),
              // Foreground: PageView + controls
              Column(
                children: [
                  // Skip button (not on last page)
                  if (!isLastPage)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.pagePadding,
                          top: AppSpacing.sm,
                        ),
                        child: TextButton(
                          onPressed: onSkip,
                          child: Text(
                            context.tr('onboarding_v2_skip'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.xxxl),

                  // PageView
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      onPageChanged: onPageChanged,
                      children: [
                        const OnboardingHookPage(),
                        const OnboardingQuestionsPage(),
                        const OnboardingPowersPage(),
                        const OnboardingDiamondsPage(),
                        OnboardingLanguagePage(
                          selectedLanguages: selectedLanguages,
                          onToggle: onLanguageToggle,
                          allSelected: allLanguagesSelected,
                          onSelectAll: selectAllLanguages,
                          onReset: resetLanguages,
                        ),
                      ],
                    ),
                  ),

                  // Bottom bar
                  OnboardingBottomBar(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    isLastPage: isLastPage,
                    onNext: onNext,
                    onStart: onStart,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
