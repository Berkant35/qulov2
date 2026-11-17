import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class RegisterStepLocation extends StatelessWidget {
  final bool locationGranted;
  final bool isRequesting;
  final String? errorText;
  final VoidCallback onRequestLocation;
  final VoidCallback onContinue;

  /// "Şehir seç": izin dayatılmaz, şehir seçimi izinle eşit ağırlıkta alternatiftir.
  final VoidCallback onPickCity;

  /// Seçilmiş şehrin adı (izin yerine); doluysa adım geçilebilir.
  final String? selectedCityName;
  final VoidCallback? onOpenSettings;

  const RegisterStepLocation({
    super.key,
    required this.locationGranted,
    required this.isRequesting,
    this.errorText,
    required this.onRequestLocation,
    required this.onContinue,
    required this.onPickCity,
    this.selectedCityName,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasCity = selectedCityName != null;
    final canContinue = locationGranted || hasCity;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('step_location'),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.get('step_location_desc'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Icon(
              canContinue ? Icons.check_circle : Icons.location_on_outlined,
              size: 96,
              color: canContinue ? context.appColors.success : context.appColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (locationGranted)
            Center(
              child: Text(
                l10n.get('location_granted'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.appColors.success,
                ),
              ),
            ),
          if (hasCity && !locationGranted)
            Center(
              child: Text(
                selectedCityName!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.appColors.success,
                ),
              ),
            ),
          if (errorText != null && !locationGranted) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.appColors.error,
              ),
            ),
            if (onOpenSettings != null &&
                (errorText == l10n.get('location_permission_denied_forever') ||
                    errorText == l10n.get('location_service_disabled')))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: TextButton(
                  onPressed: onOpenSettings,
                  child: Text(l10n.get('open_settings')),
                ),
              ),
          ],
          const Spacer(),
          // Sıra: geçilebiliyorsa "Devam" ana düğme; konum izni ve şehir seçimi onun altında
          // ikincil seçenek olarak kalır (şehir seçildikten sonra da değiştirilebilir).
          if (canContinue)
            AppButton(
              label: l10n.get('continue_btn'),
              onPressed: onContinue,
            ),
          if (!locationGranted) ...[
            if (canContinue) const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.get('enable_location'),
              variant: canContinue ? AppButtonVariant.secondary : AppButtonVariant.primary,
              onPressed: isRequesting ? null : onRequestLocation,
              isLoading: isRequesting,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.get('city_picker_choose_city'),
              variant: canContinue ? AppButtonVariant.text : AppButtonVariant.secondary,
              onPressed: isRequesting ? null : onPickCity,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
