import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';

/// Hesap silme öncesi neden toplama sheet'i.
/// Tek seçim (radio) + `other` için opsiyonel serbest metin.
/// Sonuç [DeleteReasonResult] (Hesabı Sil / Atla) veya `null` (iptal) döner.
class DeleteReasonSheet extends StatefulWidget {
  const DeleteReasonSheet({super.key});

  @override
  State<DeleteReasonSheet> createState() => _DeleteReasonSheetState();
}

class _DeleteReasonSheetState extends State<DeleteReasonSheet> {
  static const int _maxReasonTextLength = 280;

  DeletionReason? _selected;
  final TextEditingController _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _onDelete() {
    if (_selected == null) return;
    final reason = _selected!;
    Navigator.of(context).pop(
      DeleteReasonResult(
        reasonCode: reason.code,
        reasonText: reason == DeletionReason.other
            ? _otherController.text.trim()
            : null,
      ),
    );
  }

  void _onSkip() {
    Navigator.of(context).pop(
      const DeleteReasonResult(reasonCode: kDeletionReasonSkipped),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
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
              child: RadioGroup<DeletionReason>(
                groupValue: _selected,
                onChanged: (value) => setState(() => _selected = value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final reason in DeletionReason.values)
                    RadioListTile<DeletionReason>(
                      value: reason,
                      title: Text(context.tr(reason.labelKey)),
                      contentPadding: EdgeInsets.zero,
                      activeColor: colors.primary,
                      dense: true,
                    ),
                  if (_selected == DeletionReason.other)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: TextField(
                        controller: _otherController,
                        maxLength: _maxReasonTextLength,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: context.tr('delete_reason_other_hint'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _selected == null ? null : _onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(context.tr('delete_reason_submit')),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _onSkip,
            child: Text(context.tr('delete_reason_skip')),
          ),
        ],
      ),
    );
  }
}
