import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/settings/models/visibility_gate.dart';

/// "Eşleşme yok" diyen kullanıcıya, silmeden önce profilinin durumunu gösteren
/// kart. İki hâli var ve ikisi birbirini dışlar:
///
/// - **Eksik kapı varsa:** başlık + neden görünmediği + eksiklerin listesi.
/// - **Eksik kapı yoksa:** profil görünür durumda; geriye kalan tek sistematik
///   açıklama dil kuralı, o yüzden yalnızca o not gösterilir. Eksiği olana bu
///   notu da vermek gürültü olurdu — onun sorunu zaten listede.
///
/// TASARIM SINIRI: bu bir tutma ekranı değil. Silme butonu her zaman erişilebilir
/// kalır, kart hiçbir şeyi engellemez, geri sayım ya da suçluluk metni içermez.
class VisibilityChecklistCard extends StatelessWidget {
  const VisibilityChecklistCard({super.key, required this.gates});

  /// Kullanıcının geçemediği kapılar. Boş liste, "profil görünür" hâlidir ve
  /// kartı dil notu moduna alır.
  final List<VisibilityGate> gates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final hasGates = gates.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              hasGates
                  ? 'visibility_checklist_title'
                  : 'visibility_visible_title',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (hasGates) ...[
            Text(
              context.tr('visibility_checklist_intro'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...gates.map(
              (gate) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        context.tr(gate.labelKey),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Text(
              context.tr('visibility_language_note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
