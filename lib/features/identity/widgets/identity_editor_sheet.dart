import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/identity/mixins/identity_editor_sheet_mixin.dart';
import 'package:qulo_v2/features/identity/widgets/identity_chip_group.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_checkbox.dart';

/// Kimlik & yönelim etiketlerini seçme/silme sayfası. Yalnız profil bilgisi; eşleşmeye etkisi yok.
class IdentityEditorSheet extends ConsumerStatefulWidget {
  final String entryPoint;

  const IdentityEditorSheet({super.key, required this.entryPoint});

  @override
  ConsumerState<IdentityEditorSheet> createState() => _IdentityEditorSheetState();
}

class _IdentityEditorSheetState extends ConsumerState<IdentityEditorSheet>
    with IdentityEditorSheetMixin {
  @override
  void initState() {
    super.initState();
    initEditor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = errorKey;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('identity_sheet_title'), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(context.tr('identity_sheet_subtitle'), style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            IdentityChipGroup(
              titleKey: 'identity_group_orientation',
              labels: IdentityLabels.orientation,
              labelKeyOf: IdentityLabels.orientationKey,
              selected: selectedOrientation,
              onToggle: isSaving ? null : toggleOrientation,
              limitHit: orientationLimitHit,
            ),
            const SizedBox(height: AppSpacing.lg),
            IdentityChipGroup(
              titleKey: 'identity_group_gender',
              labels: IdentityLabels.gender,
              labelKeyOf: IdentityLabels.genderKey,
              selected: selectedGender,
              onToggle: isSaving ? null : toggleGender,
              limitHit: genderLimitHit,
            ),
            if (needsConsentBox) ...[
              const SizedBox(height: AppSpacing.lg),
              PrefConsentCheckbox(
                labelKey: 'identity_consent_checkbox',
                value: consentGiven,
                onChanged: setConsent,
                onOpenPolicy: openPolicy,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.tr('identity_save'),
              isLoading: isSaving,
              onPressed: canSave ? save : null,
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(error),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
