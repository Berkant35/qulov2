import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_indicators.dart';

/// Tanıtımın alt çubuğu: sayfa göstergeleri + İleri / Başla.
///
/// [showsNext] false iken (interaktif demo sayfası) düğme ve üstündeki boşluk kalkar, göstergeler
/// kalır; yükseklik değişimi kaydırırken sıçramasın diye yumuşak.
class OnboardingBottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLastPage;
  final bool showsNext;
  final VoidCallback onNext;
  final VoidCallback onStart;

  const OnboardingBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.isLastPage,
    required this.showsNext,
    required this.onNext,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnboardingIndicators(
              count: totalPages,
              currentPage: currentPage,
            ),
            AnimatedSize(
              duration: reduceMotionOf(context) ? Duration.zero : AppDurations.pageTransition,
              alignment: Alignment.topCenter,
              child: showsNext
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: context.appColors.primaryButtonGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: ElevatedButton(
                            onPressed: isLastPage ? onStart : onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            child: Text(
                              isLastPage
                                  ? context.tr('onboarding_v2_start')
                                  : context.tr('onboarding_v2_next'),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
