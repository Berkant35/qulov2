import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/pref_consent/mixins/pref_consent_sheet_mixin.dart';

/// Rızasız alınmış tercih için bir kerelik açık rıza sayfası. Kapatılamaz; iki cevap da kalıcı.
class PrefConsentSheet extends ConsumerStatefulWidget {
  const PrefConsentSheet({super.key});

  @override
  ConsumerState<PrefConsentSheet> createState() => _PrefConsentSheetState();
}

class _PrefConsentSheetState extends ConsumerState<PrefConsentSheet> with PrefConsentSheetMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = errorKey;
    // Uzun çeviri / büyük yazı: kapatılamayan sayfada düğmeler kırpılmasın diye kaydırılır.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('pref_consent_sheet_title'), style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Text(context.tr('pref_consent_sheet_body'), style: theme.textTheme.bodyMedium),
          TextButton(
            onPressed: openPolicy,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(context.tr('pref_consent_read_policy')),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: context.tr('pref_consent_accept'), onPressed: isSubmitting ? null : accept),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr(error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: isSubmitting ? null : reject,
              child: Text(context.tr('pref_consent_reject')),
            ),
          ),
        ],
      ),
    );
  }
}
