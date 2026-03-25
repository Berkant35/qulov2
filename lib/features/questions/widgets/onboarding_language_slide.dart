import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class OnboardingLanguageSlide extends StatelessWidget {
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggle;

  const OnboardingLanguageSlide({
    super.key,
    required this.selectedLanguages,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appColors.primary.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: Text(
                '\u{1F30D}',
                style: TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            context.tr('onboarding_questions_slide4_title'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('onboarding_questions_slide4_desc'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
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
              final flag = AppConstants.localeFlagEmojis[locale] ?? '';
              return FilterChip(
                label: Text('$flag ${context.tr('locale_$locale')}'),
                selected: isSelected,
                onSelected: (_) => onToggle(locale),
                selectedColor: context.appColors.primarySurface,
                checkmarkColor: context.appColors.primary,
                side: BorderSide(
                  color: isSelected ? context.appColors.primary : context.appColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
