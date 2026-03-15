import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/chat/screens/chat_screen.dart';
import 'package:qulo_v2/features/chat/sheets/create_question_sheet.dart';
import 'package:qulo_v2/features/chat/widgets/reaction_picker.dart';

mixin ChatScreenMixin on ConsumerState<ChatScreen> {
  final msgCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  RealtimeChannel? _channel;
  RealtimeChannel? _typingChannel;
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
      ref.read(chatProvider(widget.matchId).notifier).loadMessages();
      ref.read(chatProvider(widget.matchId).notifier).markAsRead();
      ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
      _subscribeRealtime();
      _subscribeTyping();
    });
  }

  void disposeMixin() {
    _chatStopwatch.stop();
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
    _typingDebounce?.cancel();
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
            final newMsg = MessageModel.fromJson(payload.newRecord);
            if (newMsg.senderId != myId) {
              ref
                  .read(chatProvider(widget.matchId).notifier)
                  .addRealtimeMessage(newMsg);
              ref.read(chatProvider(widget.matchId).notifier).markAsRead();
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => scrollToBottom());
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
          color: AppColors.surfaceElevated,
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
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  title: Text(
                    'Mesaji Sil',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.error),
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

  // ─── Question Sheet ───

  void showCreateQuestionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateQuestionSheet(
        matchId: widget.matchId,
        onSubmit: (data) async {
          final service = ref.read(chatQuestionServiceProvider);
          final question =
              await service.createQuestion(widget.matchId, data);
          ref.read(chatQuestionCacheProvider.notifier).update((state) => {
                ...state,
                question.id: question,
              });
          ref.invalidate(diamondProvider);
          await ref
              .read(chatProvider(widget.matchId).notifier)
              .loadMessages();
          WidgetsBinding.instance
              .addPostFrameCallback((_) => scrollToBottom());
        },
      ),
    );
  }

  // ─── Unmatch ───

  Future<void> confirmUnmatch() async {
    final nav = ref.read(navigationServiceProvider);
    final confirm = await nav.showAppDialog<bool>(
      const ConfirmDialog(
        name: 'unmatch',
        title: 'Unmatch',
        message:
            'Bu kisiyle eslesmeni kaldirmak istedigine emin misin? Bu islem geri alinamaz.',
        confirmText: 'Unmatch',
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
    final chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    if (chatState == null) return;
    if (chatState.mediaEnabled) {
      _showPhotoSourceSheet();
    } else {
      _showMediaConsentDialog();
    }
  }

  Future<void> _showMediaConsentDialog() async {
    final confirmed =
        await ref.read(navigationServiceProvider).showAppDialog<bool>(
              const ConfirmDialog(
                name: 'media_consent',
                title: 'Medya Paylasimi',
                message:
                    'Medya paylasmak icin karsi tarafin da onay vermesi gerekiyor. Istek gonderilsin mi?',
                confirmText: 'Istek Gonder',
                cancelText: 'Iptal',
              ),
            );
    if (confirmed == true) {
      await ref.read(chatProvider(widget.matchId).notifier).requestMedia();
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden Sec'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Kamera'),
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
    final picked = source == ImageSource.gallery
        ? await picker.pickFromGallery()
        : await picker.pickFromCamera();
    if (picked == null) return;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = 'chat-media/${widget.matchId}/$fileName';

    try {
      await Supabase.instance.client.storage
          .from('chat-media')
          .uploadBinary(storagePath, picked.bytes);

      final url = Supabase.instance.client.storage
          .from('chat-media')
          .getPublicUrl(storagePath);

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
          const SnackBar(
              content: Text('Fotograf gonderilemedi. Lutfen tekrar deneyin.')),
        );
      }
    }
  }

  // ─── Voice ───

  void startVoiceRecording() {
    final chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    if (chatState == null) return;
    if (!chatState.mediaEnabled) {
      _showMediaConsentDialog();
      return;
    }
    setState(() => isRecording = true);
  }

  Future<void> handleVoiceComplete(
      String filePath, int durationSeconds) async {
    setState(() => isRecording = false);

    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final storagePath = 'chat-media/${widget.matchId}/$fileName';

    try {
      await Supabase.instance.client.storage
          .from('chat-media')
          .upload(storagePath, file);

      final url = Supabase.instance.client.storage
          .from('chat-media')
          .getPublicUrl(storagePath);

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
          const SnackBar(
              content:
                  Text('Sesli mesaj gonderilemedi. Lutfen tekrar deneyin.')),
        );
      }
    }
  }

  void cancelVoiceRecording() {
    setState(() => isRecording = false);
  }

  Future<void> handleDisableMedia() async {
    final confirmed =
        await ref.read(navigationServiceProvider).showAppDialog<bool>(
              const ConfirmDialog(
                name: 'media_disable',
                title: 'Medya Paylasimini Kapat',
                message:
                    'Medya paylasimini kapatmak istediginize emin misiniz?',
                confirmText: 'Kapat',
                isDestructive: true,
              ),
            );
    if (confirmed == true) {
      await ref.read(chatProvider(widget.matchId).notifier).disableMedia();
    }
  }

  // ─── Helpers ───

  String formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return '';
    try {
      final dt = DateTime.parse(lastSeen);
      final now = DateTime.now().toUtc();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Son gorulme: az once';
      if (diff.inMinutes < 60) return 'Son gorulme: ${diff.inMinutes} dk once';
      if (diff.inHours < 24) return 'Son gorulme: ${diff.inHours} saat once';
      if (diff.inDays < 7) return 'Son gorulme: ${diff.inDays} gun once';
      return 'Son gorulme: ${diff.inDays ~/ 7} hafta once';
    } catch (_) {
      return '';
    }
  }

  Map<String, int> groupReactions(List<MessageReaction> reactions) {
    final map = <String, int>{};
    for (final r in reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return map;
  }
}
