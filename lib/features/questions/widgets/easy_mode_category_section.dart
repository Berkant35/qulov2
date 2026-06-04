import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';

class EasyModeCategorySection extends StatelessWidget {
  const EasyModeCategorySection({
    required this.selectedLocale,
    required this.selectedCategory,
    required this.onLanguageChipPressed,
    required this.onCategorySelected,
    required this.onProfileBased,
    super.key,
  });

  final String selectedLocale;
  final String? selectedCategory;
  final VoidCallback onLanguageChipPressed;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onProfileBased;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language chip
          Row(
            children: [
              Text(
                context.tr('question_language'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionChip(
                avatar: Text(
                  AppConstants.localeFlagEmojis[selectedLocale] ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                label: Text(context.tr('locale_$selectedLocale')),
                onPressed: onLanguageChipPressed,
                side: BorderSide(color: context.appColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            context.tr('ai_suggest_category'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: AppConstants.questionCategories.map((cat) {
              final isSelected = selectedCategory == cat;
              return FilterChip(
                selected: isSelected,
                label: Text(context.tr('question_category_$cat')),
                onSelected: (_) => onCategorySelected(cat),
                selectedColor: context.appColors.primarySurface,
                checkmarkColor: context.appColors.primary,
                side: BorderSide(
                  color: isSelected
                      ? context.appColors.primary
                      : context.appColors.border,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Profile-based button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onProfileBased,
              icon: AppIcon(
                QIcons.wand,
                size: 18,
                color: context.appColors.primary,
              ),
              label: Text(context.tr('ai_suggest_profile')),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appColors.primary,
                side: BorderSide(color: context.appColors.primary),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
