import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/features/settings/models/deletion_reason.dart';
import 'package:qulo_v2/features/settings/widgets/delete_reason_sheet.dart';

/// [DeleteReasonSheet] mantığı: seçim, "Diğer" metin alanına odak/kaydırma, sonuç.
mixin DeleteReasonSheetMixin on ConsumerState<DeleteReasonSheet> {
  DeletionReason? selected;
  final otherController = TextEditingController();
  final otherFocusNode = FocusNode();
  final otherFieldKey = GlobalKey();

  @override
  void dispose() {
    otherController.dispose();
    otherFocusNode.dispose();
    super.dispose();
  }

  void onReasonChanged(DeletionReason? value) {
    setState(() => selected = value);
    if (value == DeletionReason.other) {
      // Alan bir sonraki karede listenin sonunda belirir: odaklan (klavye açılır)
      // ve görünür alana kaydır. Klavye açıldıkça imleci EditableText görünür tutar.
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealOtherField());
    } else {
      otherFocusNode.unfocus();
    }
  }

  void _revealOtherField() {
    if (!mounted) return;
    otherFocusNode.requestFocus();
    final fieldContext = otherFieldKey.currentContext;
    if (fieldContext == null) return;
    Scrollable.ensureVisible(
      fieldContext,
      duration: AppDurations.scrollReveal,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  void onDelete() {
    final reason = selected;
    if (reason == null) return;
    ref
        .read(navigationServiceProvider)
        .closeOverlay(DeleteReasonResult.fromSelection(reason, otherController.text));
  }

  void onSkip() =>
      ref.read(navigationServiceProvider).closeOverlay(DeleteReasonResult.skipped);
}
