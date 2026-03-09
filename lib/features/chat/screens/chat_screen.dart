import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider(widget.matchId).notifier).loadMessages();
      ref.read(chatProvider(widget.matchId).notifier).markAsRead();
      _subscribeRealtime();
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

  @override
  void dispose() {
    _channel?.unsubscribe();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ref.read(chatProvider(widget.matchId).notifier).sendMessage(text);
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
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
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
                    );
                  },
                );
              },
            ),
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
