import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/questions/mixins/question_onboarding_screen_mixin.dart';
import 'package:qulo_v2/features/questions/widgets/onboarding_bottom_section.dart';
import 'package:qulo_v2/features/questions/widgets/onboarding_language_slide.dart';
import 'package:qulo_v2/features/questions/widgets/onboarding_slide.dart';

class QuestionOnboardingScreen extends ConsumerStatefulWidget {
  const QuestionOnboardingScreen({super.key});

  @override
  ConsumerState<QuestionOnboardingScreen> createState() =>
      _QuestionOnboardingScreenState();
}

class _QuestionOnboardingScreenState
    extends ConsumerState<QuestionOnboardingScreen>
    with QuestionOnboardingScreenMixin {
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.appColors.primary.withValues(alpha: 0.08),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  children: [
                    OnboardingSlide(
                      iconPath: QIcons.icHelpCircle,
                      title: context.tr('onboarding_questions_slide1_title'),
                      description:
                          context.tr('onboarding_questions_slide1_desc'),
                      iconColor: context.appColors.primary,
                    ),
                    OnboardingSlide(
                      iconPath: QIcons.icWand,
                      title: context.tr('onboarding_questions_slide2_title'),
                      description:
                          context.tr('onboarding_questions_slide2_desc'),
                      iconColor: context.appColors.primary,
                    ),
                    OnboardingSlide(
                      iconPath: QIcons.icGem,
                      title: context.tr('onboarding_questions_slide3_title'),
                      description:
                          context.tr('onboarding_questions_slide3_desc'),
                      iconColor: context.appColors.secondary,
                    ),
                    OnboardingLanguageSlide(
                      selectedLanguages: selectedLanguages,
                      onToggle: onLanguageToggle,
                    ),
                  ],
                ),
              ),
              OnboardingBottomSection(
                currentPage: currentPage,
                totalPages: 4,
                onStart: onStart,
                onSkip: onSkip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
