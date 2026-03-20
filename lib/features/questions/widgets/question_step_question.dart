import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';

class QuestionStepQuestion extends StatelessWidget {
  final TextEditingController questionTextController;
  final String selectedLocale;
  final String? selectedCategory;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<String?> onCategoryChanged;

  const QuestionStepQuestion({
    super.key,
    required this.questionTextController,
    required this.selectedLocale,
    required this.selectedCategory,
    required this.onLocaleChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                QIcon(QIcons.icWand, size: 28, color: AppColors.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('question_create_motto'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr('question_create_motto_tip'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Question text field
          AppTextField(
            controller: questionTextController,
            label: context.tr('question'),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xl),

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
                onPressed: () async {
                  final result = await showModalBottomSheet<List<String>>(
                    context: context,
                    builder: (_) => LanguagePickerSheet(
                      selectedLanguages: [selectedLocale],
                      multiSelect: false,
                    ),
                  );
                  if (result != null && result.isNotEmpty) {
                    onLocaleChanged(result.first);
                  }
                },
                side: BorderSide(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Category selection
          Text(
            context.tr('question_create_select_category'),
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
                onSelected: (selected) {
                  onCategoryChanged(selected ? cat : null);
                },
                selectedColor: AppColors.primarySurface,
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : context.appColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
