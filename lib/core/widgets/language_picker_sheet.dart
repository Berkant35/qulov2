import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class LanguagePickerSheet extends StatefulWidget {
  final List<String> selectedLanguages;
  final bool multiSelect;

  const LanguagePickerSheet({
    super.key,
    required this.selectedLanguages,
    this.multiSelect = true,
  });

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.multiSelect
                ? context.tr('language_picker_title')
                : context.tr('language_picker_select_one'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: AppConstants.supportedQuestionLocales.map((locale) {
              final isSelected = _selected.contains(locale);
              final flag = AppConstants.localeFlagEmojis[locale] ?? '';
              return FilterChip(
                label: Text('$flag ${context.tr('locale_$locale')}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (widget.multiSelect) {
                      if (selected) {
                        _selected.add(locale);
                      } else if (_selected.length > 1) {
                        _selected.remove(locale);
                      }
                    } else {
                      _selected = [locale];
                    }
                  });
                },
                selectedColor: context.appColors.primarySurface,
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : context.appColors.border,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (widget.multiSelect)
            Text(
              context.tr('language_picker_hint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (widget.multiSelect) const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(context.tr('save')),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
