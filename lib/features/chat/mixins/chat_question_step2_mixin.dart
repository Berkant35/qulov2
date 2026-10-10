import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_step2.dart';
import 'package:qulo_v2/features/email_verification/email_verification_controller.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Sohbet sorusu 2. adımı: ipucu alanı ve ödül fotoğrafı yükleme.
mixin ChatQuestionStep2Mixin on ConsumerState<ChatQuestionStep2> {
  late final hintCtrl = TextEditingController(text: widget.hintText);
  bool isUploading = false;

  void syncHintText() {
    if (widget.hintText != hintCtrl.text) hintCtrl.text = widget.hintText;
  }

  void disposeMixin() => hintCtrl.dispose();

  Future<void> pickPhoto() async {
    final picker = ref.read(imagePickerManagerProvider);
    // Izin reddi eskiden yakalanmiyordu: kullanici hicbir geri bildirim almiyordu.
    final picked = await pickWithPermissionPrompt(ref, context, picker.pickFromGallery);
    if (picked == null || !mounted) return;

    setState(() => isUploading = true);
    try {
      final result = await ref.read(chatRepositoryProvider).uploadQuestionMedia(
            widget.matchId,
            bytes: picked.bytes,
            mimeType: picked.mimeType,
          );
      switch (result) {
        case Success(data: final url):
          widget.onChanged(rewardMediaUrl: url, rewardMediaType: 'image');
        case Failure(:final failure):
          // Doğrulanmamış e-posta (403 EMAIL_VERIFICATION_REQUIRED) → doğrulama sayfası.
          final gated = await ref
              .read(emailVerificationControllerProvider)
              .handleFailure(failure, trigger: EmailVerifyTrigger.question);
          if (!gated && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('chat_media_upload_failed'))),
            );
          }
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }
}
