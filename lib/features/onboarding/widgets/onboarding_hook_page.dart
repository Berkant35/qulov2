import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class OnboardingHookPage extends StatelessWidget {
  const OnboardingHookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(AppAssets.lottieRadar),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            context.tr('onboarding_v2_page1_title'),
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('onboarding_v2_page1_desc'),
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
