import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

/// Profile Setup Gate's third hard-gate card: collects user's discover gender
/// preference (MAN/WOMAN/BOTH). Symmetric with [SetupPhotoCard] and
/// [SetupQuestionCard] — same AnimatedContainer + isComplete + check_circle
/// pattern. Once selected, the card collapses to the "done" state.
class SetupGenderPrefCard extends StatelessWidget {
  final String? selectedValue;
  final bool isProcessing;
  final ValueChanged<String> onSelect;

  const SetupGenderPrefCard({
    super.key,
    required this.selectedValue,
    required this.isProcessing,
    required this.onSelect,
  });

  bool get isComplete => selectedValue != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isComplete ? colors.primarySurface : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isComplete ? colors.primary : theme.colorScheme.outline,
          width: 2,
        ),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 28,
                color: isComplete
                    ? colors.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        isComplete
                            ? 'setup_gender_pref_done'
                            : 'setup_gender_pref_title',
                      ),
                      style: theme.textTheme.titleLarge,
                    ),
                    if (!isComplete) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr('setup_gender_pref_subtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isProcessing)
                const AppLoadingWidget.small()
              else if (isComplete)
                Icon(Icons.check_circle, size: 24, color: colors.primary),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _SetupPrefOption(
                    label: context.tr('setup_gender_pref_men'),
                    icon: Icons.male,
                    isSelected: selectedValue == 'MAN',
                    isDisabled: isProcessing,
                    onTap: () => onSelect('MAN'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SetupPrefOption(
                    label: context.tr('setup_gender_pref_women'),
                    icon: Icons.female,
                    isSelected: selectedValue == 'WOMAN',
                    isDisabled: isProcessing,
                    onTap: () => onSelect('WOMAN'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SetupPrefOption(
                    label: context.tr('setup_gender_pref_both'),
                    icon: Icons.transgender,
                    isSelected: selectedValue == 'BOTH',
                    isDisabled: isProcessing,
                    onTap: () => onSelect('BOTH'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupPrefOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SetupPrefOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primarySurface : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? colors.primary : theme.colorScheme.outline,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? colors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colors.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
