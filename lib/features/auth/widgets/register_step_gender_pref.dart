import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_checkbox.dart';

/// Signup step: discover gender preference. Symmetric with
/// [RegisterStepGender] — same Padding + 3 cards + AppButton continue layout.
class RegisterStepGenderPref extends StatelessWidget {
  final String? selectedValue;
  final ValueChanged<String> onSelected;
  final String? errorText;
  final VoidCallback onContinue;
  final bool consentGranted;
  final ValueChanged<bool> onConsentChanged;
  final VoidCallback onDeclineConsent;
  final VoidCallback onOpenPolicy;

  const RegisterStepGenderPref({
    super.key,
    this.selectedValue,
    required this.onSelected,
    this.errorText,
    required this.onContinue,
    required this.consentGranted,
    required this.onConsentChanged,
    required this.onDeclineConsent,
    required this.onOpenPolicy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      // Sabit yükseklikli PageView içinde: küçük ekran / büyük yazı tipinde
      // içerik kaydırılır, düğmeler kırpılmaz; yer varsa düğmeler altta kalır.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('register_gender_pref_title'),
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.get('register_gender_pref_subtitle'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrefConsentCheckbox(
                    value: consentGranted,
                    onChanged: onConsentChanged,
                    onOpenPolicy: onOpenPolicy,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PrefCard(
                    label: l10n.get('register_gender_pref_men'),
                    icon: Icons.male,
                    isSelected: selectedValue == 'MAN',
                    onTap: consentGranted ? () => onSelected('MAN') : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PrefCard(
                    label: l10n.get('register_gender_pref_women'),
                    icon: Icons.female,
                    isSelected: selectedValue == 'WOMAN',
                    onTap: consentGranted ? () => onSelected('WOMAN') : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PrefCard(
                    label: l10n.get('register_gender_pref_both'),
                    icon: Icons.transgender,
                    isSelected: selectedValue == 'BOTH',
                    onTap: consentGranted ? () => onSelected('BOTH') : null,
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
                    label: l10n.get('register_gender_pref_continue'),
                    onPressed: selectedValue == null || !consentGranted
                        ? null
                        : onContinue,
                  ),
                  TextButton(
                    onPressed: onDeclineConsent,
                    child: Text(l10n.get('pref_consent_continue_without')),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrefCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PrefCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? context.appColors.primarySurface
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? context.appColors.primary
                  : Theme.of(context).colorScheme.outline,
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
                color: isSelected
                    ? context.appColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
