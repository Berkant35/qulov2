import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';
import 'package:qulo_v2/features/onboarding/mixins/onboarding_screen_mixin.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_bottom_bar.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_diamonds_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_hook_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_language_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_powers_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_questions_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/parallax_background.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';

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
    // Sunucu anahtarı: açık → 3. sayfa interaktif demo, kapalı → eski statik ızgara.
    final powerDemoEnabled = ref.watch(powerDemoEnabledProvider);
    // Raw Scaffold: tam ekran gradient + parallax animasyonlu arka plan (Scaffold
    // Kurali istisnasi) — AppScaffold'un arka plan boyasi ve padding'i istenmez.
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
                  // Genel Atla: son sayfada yer tutucu, demo sayfasında hiçbiri (demonun kendi
                  // Atla'sı var, alan demonun). Yükseklik değişimi kaydırırken sıçramasın.
                  AnimatedSize(
                    duration: reduceMotionOf(context) ? Duration.zero : AppDurations.pageTransition,
                    alignment: Alignment.topCenter,
                    child: showsGeneralSkip(powerDemoEnabled: powerDemoEnabled)
                        ? Align(
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
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.inkOnDark.withValues(alpha: 0.5),
                                      ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: showsTopSpacer(powerDemoEnabled: powerDemoEnabled) ? AppSpacing.xxxl : 0,
                          ),
                  ),

                  // PageView
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      onPageChanged: onPageChanged,
                      children: [
                        const OnboardingHookPage(),
                        const OnboardingQuestionsPage(),
                        // Demo sayfadan çıkarken (kaydırma dahil, girişte de) atlama kaydını
                        // kendisi atar; sayfa keepAlive olmadığı için bu çalışır. Yerleşmeden
                        // (kaydırırken bir anlığına) kurulup kaldırılan sayfa kayıt atmaz.
                        if (powerDemoEnabled)
                          PowerDemoView(
                            entryPoint: PowerDemoEntryPoint.onboarding,
                            isActive: isPowersPage,
                            onExit: onNext,
                          )
                        else
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
                    showsNext: showsNextButton(powerDemoEnabled: powerDemoEnabled),
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
