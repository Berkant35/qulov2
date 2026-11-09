import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';

/// Silme nedeni radyo listesi + "Diğer" seçiliyken serbest metin alanı.
class DeleteReasonOptions extends StatelessWidget {
  const DeleteReasonOptions({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.otherController,
    required this.otherFocusNode,
    required this.otherFieldKey,
  });

  static const int maxReasonTextLength = 280;

  final DeletionReason? selected;
  final ValueChanged<DeletionReason?> onChanged;
  final TextEditingController otherController;
  final FocusNode otherFocusNode;
  final Key otherFieldKey;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<DeletionReason>(
      groupValue: selected,
      onChanged: onChanged,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final reason in DeletionReason.values)
            RadioListTile<DeletionReason>(
              value: reason,
              title: Text(context.tr(reason.labelKey)),
              contentPadding: EdgeInsets.zero,
              activeColor: context.appColors.primary,
              dense: true,
            ),
          if (selected == DeletionReason.other)
            Padding(
              key: otherFieldKey,
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: TextField(
                controller: otherController,
                focusNode: otherFocusNode,
                maxLength: maxReasonTextLength,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: context.tr('delete_reason_other_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
