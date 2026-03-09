import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/quiz_summary_provider.dart';
import 'package:qulo_v2/features/chat/widgets/quiz_summary_card.dart';
import 'package:qulo_v2/features/chat/widgets/typing_indicator.dart';
import 'package:qulo_v2/features/chat/widgets/reaction_picker.dart';

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
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatOpen,
      params: {AnalyticsEvents.paramChatId: widget.matchId},
    );
    Future.microtask(() {
      ref.read(chatProvider(widget.matchId).notifier).loadMessages();
      ref.read(chatProvider(widget.matchId).notifier).markAsRead();
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.matchId));
    final myId = ref.watch(authProvider).userId;
    final theme = Theme.of(context);

    final quizSummary = ref.watch(quizSummaryProvider(widget.matchId));

    return AppScaffold(
      title: context.tr('chat'),
      padding: EdgeInsets.zero,
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
                            Container(
                              margin: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                gradient: msg.isDeleted ? null : (isMe ? AppColors.primaryButtonGradient : null),
                                color: msg.isDeleted
                                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                    : (isMe ? null : theme.colorScheme.surfaceContainerHighest),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: msg.isDeleted
                                  ? Text(
                                      'Bu mesaj silindi',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : Text(
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
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryButtonGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _send,
                      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary, size: 20),
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
