import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';

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
      chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    }
    if (chatState?.mediaEnabled == true) {
      _showPhotoSourceSheet();
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
    result.when(
      success: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('chat_media_request_sent'))),
          );
        }
      },
      failure: (failure) {
        if (!mounted) return;
        if (failure is ServerFailure && failure.code == 'MEDIA_ALREADY_ENABLED') {
          ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
          return;
        }
        final msg = switch (failure) {
          ServerFailure(code: 'MEDIA_REQUEST_PENDING') => l10n.get('chat_media_pending'),
          _ => l10n.get('chat_media_request_failed'),
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppLocalizations.of(context).get('from_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(AppLocalizations.of(context).get('from_camera')),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    final picker = ref.read(imagePickerManagerProvider);
    final PickedImage? picked;
    try {
      picked = source == ImageSource.gallery
          ? await picker.pickFromGallery()
          : await picker.pickFromCamera();
    } on ImagePickerPermissionException catch (e) {
      if (mounted) {
        await showImagePickerPermissionDialog(
          ref,
          context,
          isCamera: e.isCamera,
        );
      }
      return;
    }
    if (picked == null) return;

    try {
      final uploadResult = await ref.read(chatRepositoryProvider).uploadMedia(
        widget.matchId,
        bytes: picked.bytes,
        mimeType: picked.mimeType,
      );
      final url = uploadResult.when(success: (u) => u, failure: (_) => null);
      if (url == null) throw Exception('Upload failed');

      await ref
          .read(chatProvider(widget.matchId).notifier)
          .sendMessage(url, isImage: true);
      messagesSentCount++;
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.chatMessageSend,
        params: {
          AnalyticsEvents.paramChatId: widget.matchId,
          AnalyticsEvents.paramType: 'photo',
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).get('chat_photo_send_failed'))),
        );
      }
    }
  }

  // ─── Voice ───

  Future<void> startVoiceRecording() async {
    var chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    if (chatState == null) return;
    if (!chatState.mediaEnabled) {
      await ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
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
      final uploadResult = await ref.read(chatRepositoryProvider).uploadMedia(
        widget.matchId,
        file: file,
        mimeType: 'audio/m4a',
      );
      final url = uploadResult.when(success: (u) => u, failure: (_) => null);
      if (url == null) throw Exception('Upload failed');

      await ref.read(chatProvider(widget.matchId).notifier).sendMessage(
          'Sesli mesaj',
          audioUrl: url,
          audioDurationSeconds: durationSeconds);
      messagesSentCount++;
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.chatMessageSend,
        params: {
          AnalyticsEvents.paramChatId: widget.matchId,
          AnalyticsEvents.paramType: 'voice',
          AnalyticsEvents.paramDurationMs: durationSeconds * 1000,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).get('chat_voice_send_failed'))),
        );
      }
    }
  }

  void cancelVoiceRecording() {
    setState(() => isRecording = false);
  }

  Future<void> handleDisableMedia() async {
    final l10n = AppLocalizations.of(context);
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
    if (confirmed == true) {
      await ref.read(chatProvider(widget.matchId).notifier).disableMedia();
    }
  }
}
