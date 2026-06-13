import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class OnboardingDiamondsPage extends StatelessWidget {
  const OnboardingDiamondsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Lottie.asset(AppAssets.lottieBuyDiamond),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Mini visual flow: power icon -> arrow -> green diamond
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Purple glow circle with power icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySurface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(51),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    QIcons.icLightbulb,
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.arrow_forward,
                color: Colors.white.withAlpha(128),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              // Green glow circle with green diamond
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondarySurface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withAlpha(51),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.greenDiamond,
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.tr('onboarding_v2_page4_title'),
            style: textTheme.headlineSmall?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('onboarding_v2_page4_desc'),
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
