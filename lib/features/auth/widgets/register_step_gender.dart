import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class RegisterStepGender extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderSelected;
  final String? errorText;
  final VoidCallback onContinue;

  const RegisterStepGender({
    super.key,
    this.selectedGender,
    required this.onGenderSelected,
    this.errorText,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('step_gender'),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _GenderCard(
            label: l10n.get('man'),
            icon: Icons.male,
            isSelected: selectedGender == 'MAN',
            onTap: () => onGenderSelected('MAN'),
          ),
          const SizedBox(height: AppSpacing.md),
          _GenderCard(
            label: l10n.get('woman'),
            icon: Icons.female,
            isSelected: selectedGender == 'WOMAN',
            onTap: () => onGenderSelected('WOMAN'),
          ),
          const SizedBox(height: AppSpacing.md),
          _GenderCard(
            label: l10n.get('other'),
            icon: Icons.transgender,
            isSelected: selectedGender == 'OTHER',
            onTap: () => onGenderSelected('OTHER'),
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.appColors.error,
              ),
            ),
          ],
          const Spacer(),
          AppButton(
            label: l10n.get('continue_btn'),
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected ? context.appColors.primarySurface : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? context.appColors.primary : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.appColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? context.appColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? context.appColors.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.appColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
