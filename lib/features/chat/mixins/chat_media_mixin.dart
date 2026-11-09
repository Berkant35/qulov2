import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';
import 'package:qulo_v2/features/email_verification/email_verification_controller.dart';

/// Sesli mesajin `content` alani — arayuz metni DEGIL, cevrilmez: ses mesaji
/// `audio_url` ile ayirt edilip `VoiceMessageWidget` ile cizilir, son mesaj
/// onizlemesini sunucu dile gore uretir. Mevcut kayitlarla tutarli kalir.
const _voiceMessageContent = 'Sesli mesaj';

/// Chat ekraninda foto ve sesli mesaj akisi: medya izni istegi, kaynak secimi,
/// yukleme ve medya iznini kapatma.
///
/// `ChatScreenMixin`'den ayrildi: tek dosya 677 satira ciktu (limit 300).
mixin ChatMediaMixin on ChatScreenMixin {
  bool isRecording = false;

  // ─── Media ───

  Future<void> handlePhotoTap() async {
    var chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    if (chatState == null) return;
    if (!chatState.mediaEnabled) {
      await ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
      if (!mounted) return;
      chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    }
    if (chatState?.mediaEnabled == true) {
      await _showPhotoSourceSheet();
    } else {
      _autoRequestMedia();
    }
  }

  Future<void> _autoRequestMedia() async {
    final pending = ref.read(chatProvider(widget.matchId)).valueOrNull?.pendingMediaRequest;
    final l10n = AppLocalizations.of(context);
    if (pending != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('chat_media_pending'))),
        );
      }
      return;
    }

    final result = await ref.read(chatProvider(widget.matchId).notifier).requestMedia();
    if (!mounted) return;
    final failure = switch (result) {
      Success() => null,
      Failure(:final failure) => failure,
    };
    if (failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('chat_media_request_sent'))),
      );
      return;
    }
    final gated = await ref
        .read(emailVerificationControllerProvider)
        .handleFailure(failure, trigger: EmailVerifyTrigger.mediaRequest);
    if (gated || !mounted) return;
    if (failure is ServerFailure && failure.code == 'MEDIA_ALREADY_ENABLED') {
      ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
      return;
    }
    final msg = switch (failure) {
      ServerFailure(code: 'MEDIA_REQUEST_PENDING') => l10n.get('chat_media_pending'),
      _ => l10n.get('chat_media_request_failed'),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showPhotoSourceSheet() async {
    final source =
        await ref.read(navigationServiceProvider).showAppBottomSheet<ImageSource>(
              ListBottomSheet<ImageSource>(
                name: 'chat_photo_source',
                options: [
                  SheetOption(
                    label: context.tr('from_gallery'),
                    icon: Icons.photo_library_outlined,
                    value: ImageSource.gallery,
                  ),
                  SheetOption(
                    label: context.tr('from_camera'),
                    icon: Icons.camera_alt_outlined,
                    value: ImageSource.camera,
                  ),
                ],
              ),
            );
    if (source == null || !mounted) return;
    await _pickAndSendPhoto(source);
  }

  void respondToMediaRequest(String requestId, {required bool accept}) {
    ref
        .read(chatProvider(widget.matchId).notifier)
        .respondToMediaRequest(requestId, accept ? 'accept' : 'reject');
  }

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    final picker = ref.read(imagePickerManagerProvider);
    final picked = await pickWithPermissionPrompt(
      ref,
      context,
      () => source == ImageSource.gallery ? picker.pickFromGallery() : picker.pickFromCamera(),
    );
    if (picked == null || !mounted) return;

    try {
      final upload = await ref.read(chatRepositoryProvider).uploadMedia(
        widget.matchId,
        bytes: picked.bytes,
        mimeType: picked.mimeType,
      );
      // Yukleme surerken sohbetten cikildiysa mesaj gonderilmez (eskiden de
      // gonderilmiyordu: kapali ekranda `ref` StateError atip catch'e dusuyordu).
      if (!mounted) return;
      final String url;
      switch (upload) {
        case Success(:final data):
          url = data;
        case Failure(:final failure):
          await _onMediaFailure(failure, 'chat_photo_send_failed');
          return;
      }

      final sent = await ref
          .read(chatProvider(widget.matchId).notifier)
          .sendMessage(url, isImage: true);
      if (sent case Failure(:final failure)) {
        await _onMediaFailure(failure, 'chat_photo_send_failed');
        return;
      }
      recordMessageSent();
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.chatMessageSend,
        params: {
          AnalyticsEvents.paramChatId: widget.matchId,
          AnalyticsEvents.paramType: 'photo',
        },
      );
    } catch (_) {
      _showMediaError('chat_photo_send_failed');
    }
  }

  /// Medya gönderim hatası: doğrulama kapısıysa sayfa açılır, değilse snackbar.
  /// Gönderim await'inden sonra çağrılır — ekran kapandıysa sayfa/snackbar yok.
  Future<void> _onMediaFailure(AppFailure failure, String fallbackKey) async {
    if (!mounted) return;
    final gated = await ref
        .read(emailVerificationControllerProvider)
        .handleFailure(failure, trigger: EmailVerifyTrigger.media);
    if (!gated) _showMediaError(failure.userMessageKey(fallbackKey));
  }

  void _showMediaError(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(key))));
  }

  // ─── Voice ───

  Future<void> startVoiceRecording() async {
    var chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    if (chatState == null) return;
    if (!chatState.mediaEnabled) {
      await ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
      if (!mounted) return;
      chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    }
    if (chatState?.mediaEnabled == true) {
      setState(() => isRecording = true);
    } else {
      _autoRequestMedia();
    }
  }

  Future<void> handleVoiceComplete(
      String filePath, int durationSeconds) async {
    setState(() => isRecording = false);

    final file = File(filePath);

    try {
      final upload = await ref.read(chatRepositoryProvider).uploadMedia(
        widget.matchId,
        file: file,
        mimeType: 'audio/m4a',
      );
      // Foto akisiyla ayni: kapali ekranda gonderim yapilmaz.
      if (!mounted) return;
      final String url;
      switch (upload) {
        case Success(:final data):
          url = data;
        case Failure(:final failure):
          await _onMediaFailure(failure, 'chat_voice_send_failed');
          return;
      }

      final sent = await ref.read(chatProvider(widget.matchId).notifier).sendMessage(
          _voiceMessageContent,
          audioUrl: url,
          audioDurationSeconds: durationSeconds);
      if (sent case Failure(:final failure)) {
        await _onMediaFailure(failure, 'chat_voice_send_failed');
        return;
      }
      recordMessageSent();
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.chatMessageSend,
        params: {
          AnalyticsEvents.paramChatId: widget.matchId,
          AnalyticsEvents.paramType: 'voice',
          AnalyticsEvents.paramDurationMs: durationSeconds * 1000,
        },
      );
    } catch (_) {
      _showMediaError('chat_voice_send_failed');
    }
  }

  void cancelVoiceRecording() {
    setState(() => isRecording = false);
  }

  Future<void> handleDisableMedia() async {
    final l10n = AppLocalizations.of(context);
    // Dialog await'inden ONCE: onaydan sonra ekran kapanmis olsa da (ref dispose)
    // kullanicinin onayladigi kapatma sunucuya gider.
    final chat = ref.read(chatProvider(widget.matchId).notifier);
    final confirmed =
        await ref.read(navigationServiceProvider).showAppDialog<bool>(
              ConfirmDialog(
                name: 'media_disable',
                title: l10n.get('chat_media_disable_title'),
                message: l10n.get('chat_media_disable_message'),
                confirmText: l10n.get('chat_media_disable_confirm'),
                isDestructive: true,
              ),
            );
    if (confirmed == true) await chat.disableMedia();
  }
}
