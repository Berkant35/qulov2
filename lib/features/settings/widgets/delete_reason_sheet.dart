import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/settings/mixins/delete_reason_sheet_mixin.dart';
import 'package:qulo_v2/features/settings/models/visibility_gate.dart';
import 'package:qulo_v2/features/settings/widgets/delete_reason_options.dart';
import 'package:qulo_v2/features/settings/widgets/visibility_checklist_card.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Hesap silme öncesi neden toplama sheet'i.
/// Tek seçim (radio) + `other` için opsiyonel serbest metin.
/// Sonuç [DeleteReasonResult] (Hesabı Sil / neden belirtmeden devam) veya
/// `null` (iptal) döner.
class DeleteReasonSheet extends ConsumerStatefulWidget {
  const DeleteReasonSheet({super.key});

  @override
  ConsumerState<DeleteReasonSheet> createState() => _DeleteReasonSheetState();
}

class _DeleteReasonSheetState extends ConsumerState<DeleteReasonSheet>
    with DeleteReasonSheetMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    // Reactive wiring build'de kalir, karar mantigi model dosyasinda —
    // boylece kural test edilebilir (visibility_gate_test.dart).
    final user = ref.watch(userProvider).valueOrNull;
    final gates = gatesForDeletionReason(selected, user);
    final showCard =
        gates.isNotEmpty || shouldShowLanguageNote(selected, user);
    // Modal sheet klavyeye kendiliğinden yer açmaz: dolgu olmadan "Diğer"
    // metin alanı klavyenin altında kalıyordu (2.0.13+ boş `other` kayıtları).
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding)
          .copyWith(bottom: AppSpacing.pagePadding + keyboardInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('delete_reason_title'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('delete_reason_subtitle'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: DeleteReasonOptions(
                selected: selected,
                onChanged: onReasonChanged,
                otherController: otherController,
                otherFocusNode: otherFocusNode,
                otherFieldKey: otherFieldKey,
              ),
            ),
          ),
          // Kart kaydirma alaninin DISINDA: liste icinde olsaydi kart, onu
          // gormesi gereken kullanicinin cok asagisinda kalirdi.
          if (showCard) ...[
            const SizedBox(height: AppSpacing.sm),
            VisibilityChecklistCard(
              gates: gates,
              questionLocales: user?.questionLocales,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: selected == null ? null : onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(context.tr('delete_reason_submit')),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Neden seçmeden ilerleme: "Diğer" seçeneğiyle karışmasın diye
          // ayrı, ikincil renkte ve "neden belirtmeden" diye açık etiketli.
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(context.tr('delete_reason_skip')),
          ),
        ],
      ),
    );
  }
}
