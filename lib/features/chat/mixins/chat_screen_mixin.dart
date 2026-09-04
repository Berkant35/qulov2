import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/coach_mark_service.dart';
import 'package:qulo_v2/features/chat/coach/chat_question_coach_marks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/chat/screens/chat_screen.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/chat/widgets/reaction_picker.dart';
import 'package:qulo_v2/features/profile_detail/widgets/report_category_sheet.dart';

mixin ChatScreenMixin on ConsumerState<ChatScreen> {

  final msgCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  RealtimeChannel? _channel;
  RealtimeChannel? _typingChannel;
  RealtimeChannel? _mediaChannel;
  Timer? _mediaDebounce;
  bool _disposed = false;
  final Stopwatch _chatStopwatch = Stopwatch()..start();
  int _messagesSentCount = 0;
  bool isOtherTyping = false;
  bool isRecording = false;
  bool hasText = false;
  bool quizSummaryDismissed = false;
  Timer? _typingDebounce;

  // ─── Lifecycle ───

  void initMixin() {
    msgCtrl.addListener(_onTextChanged);
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatOpen,
      params: {AnalyticsEvents.paramChatId: widget.matchId},
    );
    scrollCtrl.addListener(_onScroll);
    _loadQuizSummaryDismissState();
    Future.microtask(() {
      // Aktif chat'i işaretle — in-app banner suppress için
      ref.read(activeChatMatchIdProvider.notifier).state = widget.matchId;
      // Clear question cache so cards re-fetch fresh data
      ref.read(chatQuestionCacheProvider.notifier).state = {};
      ref.read(openedQuestionIdsProvider.notifier).state = {};

      final notifier = ref.read(chatProvider(widget.matchId).notifier);
      notifier.loadMessages();
      notifier.markAsRead();
      ref.read(matchListProvider.notifier).clearUnreadCount(widget.matchId);
      notifier.loadMediaStatus();
      _subscribeRealtime();
      _subscribeTyping();
      _subscribeMediaRequests();
      // Question updates handled via FCM (NotificationNotifier)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CoachMarkService.instance.maybeStartTour(
          context,
          tourId: 'chat_question',
          steps: buildChatQuestionCoachSteps(),
        );
      });
    });
  }

  void disposeMixin() {
    _disposed = true;
    _chatStopwatch.stop();
    // Prevent orphaned overlay if chat is popped while coach-mark is open.
    CoachMarkService.instance.forceClose();
    // Aktif chat'i temizle — guard against disposed ref
    try {
      ref.read(activeChatMatchIdProvider.notifier).state = null;
    } catch (_) {}
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatClose,
      params: {
        AnalyticsEvents.paramChatId: widget.matchId,
        AnalyticsEvents.paramDurationMs: _chatStopwatch.elapsedMilliseconds,
        AnalyticsEvents.paramMessagesSent: _messagesSentCount,
      },
    );
    _channel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _mediaChannel?.unsubscribe();
    _mediaDebounce?.cancel();
    _typingDebounce?.cancel();
    msgCtrl.removeListener(_onTextChanged);
    scrollCtrl.removeListener(_onScroll);
    scrollCtrl.dispose();
    msgCtrl.dispose();
  }

  // ─── Text Listener ───

  void _onTextChanged() {
    final newHasText = msgCtrl.text.trim().isNotEmpty;
    if (newHasText != hasText) {
      setState(() => hasText = newHasText);
    }
  }

  // ─── Scroll ───

  void _onScroll() {
    if (!scrollCtrl.hasClients) return;
    final maxScroll = scrollCtrl.position.maxScrollExtent;
    final currentScroll = scrollCtrl.position.pixels;
    if (maxScroll - currentScroll < 200) {
      final notifier = ref.read(chatProvider(widget.matchId).notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  void scrollToBottom() {
    if (scrollCtrl.hasClients) {
      scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ─── Quiz Summary ───

  Future<void> _loadQuizSummaryDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed =
        prefs.getBool('quiz_summary_dismissed_${widget.matchId}') ?? false;
    if (dismissed && mounted) {
      setState(() => quizSummaryDismissed = true);
    }
  }

  Future<void> dismissQuizSummary() async {
    setState(() => quizSummaryDismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quiz_summary_dismissed_${widget.matchId}', true);
  }

  // ─── Realtime ───

  void _subscribeRealtime() {
    final myId = ref.read(authProvider).userId;
    _channel = Supabase.instance.client
        .channel('chat:${widget.matchId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: widget.matchId,
          ),
          callback: (payload) {
            if (_disposed) return;
            try {
              final newMsg = MessageModel.fromJson(payload.newRecord);
              if (newMsg.senderId != myId) {
                ref
                    .read(chatProvider(widget.matchId).notifier)
                    .addRealtimeMessage(newMsg);
                ref.read(chatProvider(widget.matchId).notifier).markAsRead();
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => scrollToBottom());
              }
            } catch (e) {
              debugPrint('[chat] Realtime parse error: $e');
              debugPrint('[chat] Payload: ${payload.newRecord}');
            }
          },
        )
        .subscribe();
  }

  void _subscribeTyping() {
    final myId = ref.read(authProvider).userId;
    _typingChannel =
        Supabase.instance.client.channel('typing:${widget.matchId}');
    _typingChannel!
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (_disposed) return;
            final senderId = payload['user_id'] as String?;
            if (senderId != null && senderId != myId) {
              setState(() => isOtherTyping = true);
              _typingDebounce?.cancel();
              _typingDebounce = Timer(const Duration(seconds: 3), () {
                if (mounted) setState(() => isOtherTyping = false);
              });
            }
          },
        )
        .subscribe();
  }

  void _subscribeMediaRequests() {
    _mediaChannel = Supabase.instance.client
        .channel('media:${widget.matchId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'media_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: widget.matchId,
          ),
          callback: (_) {
            if (_disposed) return;
            // Debounce: hızlı ardışık değişikliklerde tek API çağrısı yap
            _mediaDebounce?.cancel();
            _mediaDebounce = Timer(const Duration(milliseconds: 500), () {
              ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
            });
          },
        )
        .subscribe();
  }

  // Question updates come via FCM (NotificationNotifier._refreshQuestionCache).

  void sendTypingEvent() {
    final myId = ref.read(authProvider).userId;
    _typingChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': myId},
    );
  }

  // ─── Message Menu ───

  void showMessageMenu(MessageModel msg, bool isMe) {
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
              ReactionPicker(
                onReactionSelected: (emoji) {
                  Navigator.pop(context);
                  ref
                      .read(chatProvider(widget.matchId).notifier)
                      .addReaction(msg.id, emoji);
                },
              ),
              if (isMe) ...[
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: context.appColors.error),
                  title: Text(
                    AppLocalizations.of(context).get('chat_delete_message'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: context.appColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(chatProvider(widget.matchId).notifier)
                        .deleteMessage(msg.id);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Send Message ───

  Future<void> send() async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;
    msgCtrl.clear();
    await ref.read(chatProvider(widget.matchId).notifier).sendMessage(text);
    _messagesSentCount++;
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatMessageSend,
      params: {
        AnalyticsEvents.paramChatId: widget.matchId,
        AnalyticsEvents.paramType: 'text',
        AnalyticsEvents.paramCharCount: text.length,
      },
    );
  }

  // ─── Question Screen ───

  Future<void> showCreateQuestionSheet() async {
    final result = await ref.read(navigationServiceProvider).push<bool>(
      RouteNames.createChatQuestion,
      params: {'matchId': widget.matchId},
    );
    if (result == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    }
  }

  // ─── Unmatch ───

  Future<void> confirmUnmatch() async {
    final nav = ref.read(navigationServiceProvider);
    final confirm = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'unmatch',
        title: context.tr('unmatch'),
        message: context.tr('chat_unmatch_confirm'),
        confirmText: context.tr('unmatch'),
        isDestructive: true,
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(matchListProvider.notifier).unmatch(widget.matchId);
      if (mounted) {
        ref.read(navigationServiceProvider).pop();
      }
    }
  }

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
      _messagesSentCount++;
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
      _messagesSentCount++;
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

  // ─── Report & Block ───

  String? _getTargetUserId() {
    return ref.read(matchListProvider).valueOrNull
        ?.where((m) => m.matchId == widget.matchId)
        .firstOrNull
        ?.user
        ?.userId;
  }

  void onChatReport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReportCategorySheet(
        onSelected: _showChatReportReasonDialog,
      ),
    );
  }

  void _showChatReportReasonDialog(String category) {
    final nav = ref.read(navigationServiceProvider);
    final controller = TextEditingController();
    final isOther = category == 'OTHER';
    final l10n = AppLocalizations.of(context);

    nav.showAppDialog(
      CustomDialog(
        name: 'chat_report_reason',
        builder: (ctx) => AlertDialog(
          title: Text(l10n.get('report')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.get('report_reason_hint'),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => nav.closeOverlay(),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final reason = controller.text.trim();
                if (isOther && reason.isEmpty) return;
                nav.closeOverlay();
                final targetId = _getTargetUserId();
                if (targetId == null) return;
                await ref.read(reportRepositoryProvider).createReport(
                  reportedId: targetId,
                  category: category,
                  reason: reason.isNotEmpty ? reason : null,
                );
                controller.dispose();
              },
              child: Text(l10n.get('report')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onChatBlock() async {
    final l10n = AppLocalizations.of(context);
    final nav = ref.read(navigationServiceProvider);
    final confirmed = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'chat_block_user',
        title: l10n.get('block_user_title'),
        message: l10n.get('block_user_message'),
        confirmText: l10n.get('block'),
        cancelText: l10n.get('cancel'),
        isDestructive: true,
      ),
    );
    if (confirmed != true) return;
    final targetId = _getTargetUserId();
    if (targetId == null) return;
    await ref.read(blockRepositoryProvider).blockUser(targetId);
    if (mounted) {
      ref.read(navigationServiceProvider).pop();
    }
  }

  // ─── Helpers ───

  String formatLastSeen(String? lastSeen) {
    final dt = lastSeen == null ? null : DateTime.tryParse(lastSeen);
    if (dt == null) return '';
    return '${context.tr('last_seen')}: ${ref.read(formatManagerProvider).relative(dt)}';
  }

  Map<String, int> groupReactions(List<MessageReaction> reactions) {
    final map = <String, int>{};
    for (final r in reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return map;
  }
}
