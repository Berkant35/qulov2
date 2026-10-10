import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Eşleşme tercihi açık rıza kutusu — kayıt, kurulum kapısı ve bir kerelik sayfada aynı metin.
/// Her zaman İŞARETSİZ başlar (KVKK: rıza önceden işaretlenemez).
class PrefConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPolicy;

  /// Rıza metni çeviri anahtarı — varsayılan eşleşme tercihi; kimlik etiketleri kendi metnini verir.
  final String labelKey;

  const PrefConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onOpenPolicy,
    this.labelKey = 'pref_consent_checkbox',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kutu + metin tek anlamsal düğüm ve tek dokunma alanı; politika düğmesi dışarıda.
        MergeSemantics(
          child: InkWell(
            onTap: () => onChanged(!value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(context.tr(labelKey), style: theme.textTheme.bodySmall),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: kMinInteractiveDimension + AppSpacing.xs),
          child: TextButton(
            onPressed: onOpenPolicy,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            child: Text(context.tr('pref_consent_read_policy')),
          ),
        ),
      ],
    );
  }
}
