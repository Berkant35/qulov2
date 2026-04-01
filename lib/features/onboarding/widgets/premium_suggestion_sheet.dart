import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/routing/route_names.dart';

class PremiumSuggestionSheet extends ConsumerWidget {
  const PremiumSuggestionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textHint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AnalyticsManager.instance.logEvent(
                    AnalyticsEvents.onboardingV2PremiumDismissed,
                  );
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            // Subscribe Lottie
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(AppAssets.lottieSubscribe),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Title
            Text(
              context.tr('onboarding_v2_premium_title'),
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Benefits
            _BenefitRow(
              text: context.tr('onboarding_v2_premium_benefit_1'),
              color: colors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            _BenefitRow(
              text: context.tr('onboarding_v2_premium_benefit_2'),
              color: colors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            _BenefitRow(
              text: context.tr('onboarding_v2_premium_benefit_3'),
              color: colors.secondary,
            ),
            const SizedBox(height: AppSpacing.xxl),
            // CTA button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: colors.purpleGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    AnalyticsManager.instance.logEvent(
                      AnalyticsEvents.onboardingV2PremiumTapped,
                    );
                    Navigator.of(context).pop();
                    ref
                        .read(navigationServiceProvider)
                        .go(RouteNames.subscription);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    context.tr('onboarding_v2_premium_cta'),
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  final Color color;

  const _BenefitRow({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ],
    );
  }
}
