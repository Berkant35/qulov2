import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/quiz_summary_provider.dart';
import 'package:qulo_v2/features/chat/widgets/quiz_summary_card.dart';
import 'package:qulo_v2/features/chat/widgets/typing_indicator.dart';
import 'package:qulo_v2/features/chat/widgets/reaction_picker.dart';
import 'package:qulo_v2/features/chat/widgets/photo_message_widget.dart';
import 'package:qulo_v2/features/chat/widgets/voice_message_widget.dart';
import 'package:qulo_v2/features/chat/widgets/voice_recorder_overlay.dart';
import 'package:qulo_v2/features/chat/sheets/create_question_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  RealtimeChannel? _channel;
  RealtimeChannel? _typingChannel;
  final Stopwatch _chatStopwatch = Stopwatch()..start();
  int _messagesSentCount = 0;
  bool _isOtherTyping = false;
  bool _isRecording = false;
  bool _hasText = false;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatOpen,
      params: {AnalyticsEvents.paramChatId: widget.matchId},
    );
    Future.microtask(() {
      ref.read(chatProvider(widget.matchId).notifier).loadMessages();
      ref.read(chatProvider(widget.matchId).notifier).markAsRead();
      ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
      _subscribeRealtime();
      _subscribeTyping();
    });
  }

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
              ref.read(chatProvider(widget.matchId).notifier).addRealtimeMessage(newMsg);
              ref.read(chatProvider(widget.matchId).notifier).markAsRead();
            }
          },
        )
        .subscribe();
  }

  void _subscribeTyping() {
    final myId = ref.read(authProvider).userId;
    _typingChannel = Supabase.instance.client.channel('typing:${widget.matchId}');
    _typingChannel!
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final senderId = payload['user_id'] as String?;
            if (senderId != null && senderId != myId) {
              setState(() => _isOtherTyping = true);
              _typingDebounce?.cancel();
              _typingDebounce = Timer(const Duration(seconds: 3), () {
                if (mounted) setState(() => _isOtherTyping = false);
              });
            }
          },
        )
        .subscribe();
  }

  void _sendTypingEvent() {
    final myId = ref.read(authProvider).userId;
    _typingChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': myId},
    );
  }

  @override
  void dispose() {
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
    _msgCtrl.dispose();
    super.dispose();
  }

  void _showMessageMenu(MessageModel msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReactionPicker(
                onReactionSelected: (emoji) {
                  Navigator.pop(context);
                  ref.read(chatProvider(widget.matchId).notifier).addReaction(msg.id, emoji);
                },
              ),
              if (isMe) ...[
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: Text(
                    'Mesajı Sil',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(chatProvider(widget.matchId).notifier).deleteMessage(msg.id);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _groupReactions(List<MessageReaction> reactions) {
    final map = <String, int>{};
    for (final r in reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return map;
  }

  void _showCreateQuestionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateQuestionSheet(
        matchId: widget.matchId,
        onSubmit: (data) async {
          final service = ref.read(chatQuestionServiceProvider);
          await service.createQuestion(widget.matchId, data);
        },
      ),
    );
  }

  Future<void> _confirmUnmatch() async {
    final nav = ref.read(navigationServiceProvider);
    final confirm = await nav.showAppDialog<bool>(
      const ConfirmDialog(
        name: 'unmatch',
        title: 'Unmatch',
        message: 'Bu kişiyle eşleşmeyi kaldırmak istediğine emin misin? Bu işlem geri alınamaz.',
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

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return '';
    try {
      final dt = DateTime.parse(lastSeen);
      final now = DateTime.now().toUtc();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Son görülme: az önce';
      if (diff.inMinutes < 60) return 'Son görülme: ${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return 'Son görülme: ${diff.inHours} saat önce';
      if (diff.inDays < 7) return 'Son görülme: ${diff.inDays} gün önce';
      return 'Son görülme: ${diff.inDays ~/ 7} hafta önce';
    } catch (_) {
      return '';
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ref.read(chatProvider(widget.matchId).notifier).sendMessage(text);
    _messagesSentCount++;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatMessageSend,
      params: {
        AnalyticsEvents.paramChatId: widget.matchId,
        AnalyticsEvents.paramType: 'text',
        AnalyticsEvents.paramCharCount: text.length,
      },
    );
  }

  // ─── Media Methods ───

  Future<void> _handlePhotoTap() async {
    final chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    if (chatState == null) return;
    if (chatState.mediaEnabled) {
      _showPhotoSourceSheet();
    } else {
      _showMediaConsentDialog();
    }
  }

  Future<void> _showMediaConsentDialog() async {
    final confirmed = await ref.read(navigationServiceProvider).showAppDialog<bool>(
      const ConfirmDialog(
        name: 'media_consent',
        title: 'Medya Paylasimi',
        message: 'Medya paylasmak icin karsi tarafin da onay vermesi gerekiyor. Istek gonderilsin mi?',
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
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

      await ref.read(chatProvider(widget.matchId).notifier)
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
          const SnackBar(content: Text('Fotoğraf gönderilemedi. Lütfen tekrar deneyin.')),
        );
      }
    }
  }

  void _startVoiceRecording() {
    final chatState = ref.read(chatProvider(widget.matchId)).valueOrNull;
    if (chatState == null) return;
    if (!chatState.mediaEnabled) {
      _showMediaConsentDialog();
      return;
    }
    setState(() => _isRecording = true);
  }

  Future<void> _handleVoiceComplete(String filePath, int durationSeconds) async {
    setState(() => _isRecording = false);

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

      await ref.read(chatProvider(widget.matchId).notifier)
          .sendMessage('Sesli mesaj', audioUrl: url, audioDurationSeconds: durationSeconds);
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
          const SnackBar(content: Text('Sesli mesaj gönderilemedi. Lütfen tekrar deneyin.')),
        );
      }
    }
  }

  void _cancelVoiceRecording() {
    setState(() => _isRecording = false);
  }

  Future<void> _handleDisableMedia() async {
    final confirmed = await ref.read(navigationServiceProvider).showAppDialog<bool>(
      const ConfirmDialog(
        name: 'media_disable',
        title: 'Medya Paylasimini Kapat',
        message: 'Medya paylasimini kapatmak istediginize emin misiniz?',
        confirmText: 'Kapat',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      await ref.read(chatProvider(widget.matchId).notifier).disableMedia();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.matchId));
    final myId = ref.watch(authProvider).userId;
    final theme = Theme.of(context);

    final quizSummary = ref.watch(quizSummaryProvider(widget.matchId));

    // Watch matchListProvider to get user info for header
    final matchUser = ref.watch(matchListProvider).whenData((matches) {
      try {
        return matches.firstWhere((m) => m.matchId == widget.matchId).user;
      } catch (_) {
        return null;
      }
    }).valueOrNull;

    final userName = matchUser?.name ?? context.tr('chat');
    final isOnline = matchUser?.isOnline ?? false;
    final lastSeen = matchUser?.lastSeen;
    final statusText = isOnline ? 'Online' : _formatLastSeen(lastSeen);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.secondary : theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (statusText.isNotEmpty)
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOnline
                            ? AppColors.secondary
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'unmatch') _confirmUnmatch();
              if (value == 'media_disable') _handleDisableMedia();
            },
            itemBuilder: (ctx) {
              final mediaEnabled = ref.read(chatProvider(widget.matchId)).valueOrNull?.mediaEnabled ?? false;
              return [
                if (mediaEnabled)
                  PopupMenuItem(
                    value: 'media_disable',
                    child: Row(
                      children: [
                        Icon(Icons.no_photography, color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Medya paylasimini kapat'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'unmatch',
                  child: Row(
                    children: [
                      Icon(Icons.heart_broken, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      const Text('Unmatch'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Quiz Summary Card ───
          quizSummary.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) {
              if (summary == null) return const SizedBox.shrink();
              return QuizSummaryCard(
                summary: summary,
                currentUserId: myId ?? '',
              );
            },
          ),
          Expanded(
            child: chatState.when(
              loading: () => const Center(child: AppLoadingWidget.large()),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              ),
              data: (state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      context.tr('say_hello'),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  itemCount: state.messages.length,
                  itemBuilder: (_, i) {
                    final msg = state.messages[i];
                    final isMe = msg.senderId == myId;
                    final hasReactions = msg.reactions != null && msg.reactions!.isNotEmpty;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: msg.isDeleted ? null : () => _showMessageMenu(msg, isMe),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (msg.isDeleted)
                              Container(
                                margin: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  'Bu mesaj silindi',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            else if (msg.isAudio)
                              Padding(
                                padding: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
                                child: VoiceMessageWidget(
                                  audioUrl: msg.audioUrl!,
                                  durationSeconds: msg.audioDurationSeconds ?? 0,
                                  isMine: isMe,
                                ),
                              )
                            else if (msg.isImage)
                              Padding(
                                padding: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
                                child: PhotoMessageWidget(
                                  imageUrl: msg.content,
                                  isMine: isMe,
                                ),
                              )
                            else
                              Container(
                                margin: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  gradient: isMe ? AppColors.primaryButtonGradient : null,
                                  color: isMe ? null : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  msg.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            if (hasReactions)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: _groupReactions(msg.reactions!).entries.map((entry) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceInput,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                      ),
                                      child: Text(
                                        entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isOtherTyping)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.pagePadding,
                bottom: AppSpacing.xs,
              ),
              child: const TypingIndicator(),
            ),
          if (_isRecording)
            VoiceRecorderOverlay(
              onRecordComplete: _handleVoiceComplete,
              onCancel: _cancelVoiceRecording,
            )
          else
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: _handlePhotoTap,
                    icon: Icon(
                      Icons.photo_camera_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      onChanged: (_) => _sendTypingEvent(),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: context.tr('message_hint'),
                        hintStyle: TextStyle(color: theme.hintColor),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: _showCreateQuestionSheet,
                    icon: Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  if (_hasText)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryButtonGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _send,
                        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                      ),
                    )
                  else
                    GestureDetector(
                      onLongPress: _startVoiceRecording,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryButtonGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: null,
                          icon: Icon(Icons.mic, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
