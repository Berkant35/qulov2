import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class OnboardingLanguagePage extends StatelessWidget {
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggle;

  const OnboardingLanguagePage({
    super.key,
    required this.selectedLanguages,
    required this.onToggle,
  });

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
            width: 120,
            height: 120,
            child: Lottie.asset(AppAssets.lottieLocation),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.tr('onboarding_v2_page5_title'),
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: AppConstants.supportedQuestionLocales.map((locale) {
              final isSelected = selectedLanguages.contains(locale);
              final flag =
                  AppConstants.localeFlagEmojis[locale] ?? locale;

              return FilterChip(
                label: Text('$flag  $locale'),
                selected: isSelected,
                onSelected: (_) => onToggle(locale),
                selectedColor: colors.primarySurface,
                backgroundColor: colors.surface,
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.border,
                ),
                checkmarkColor: colors.primary,
                labelStyle: textTheme.bodyMedium?.copyWith(
                  color: isSelected ? colors.primary : Colors.white,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
