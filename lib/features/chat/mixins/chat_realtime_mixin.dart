import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';

/// Chat ekraninin realtime abonelikleri: mesaj insert, typing broadcast,
/// medya istegi degisiklikleri.
///
/// `ChatScreenMixin`'den ayrildi: tek dosya 677 satira ciktu (limit 300).
/// Ayni bolme deseni `ChatQuestionPowerMixin` / `QuizPowerMixin` tarafinda da var.
mixin ChatRealtimeMixin on ChatScreenMixin {
  RealtimeChannel? _channel;
  RealtimeChannel? _typingChannel;
  RealtimeChannel? _mediaChannel;
  Timer? _mediaDebounce;
  Timer? _typingDebounce;
  bool isOtherTyping = false;

  // ─── Lifecycle Kancalari ───

  @override
  void subscribeRealtime() {
    _subscribeRealtime();
    _subscribeTyping();
    _subscribeMediaRequests();
  }

  @override
  void disposeRealtime() {
    _channel?.unsubscribe();
    _typingChannel?.unsubscribe();
    _mediaChannel?.unsubscribe();
    _mediaDebounce?.cancel();
    _typingDebounce?.cancel();
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
            if (disposed) return;
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
            if (disposed) return;
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
            if (disposed) return;
            // Debounce: hizli ardisik degisikliklerde tek API cagrisi yap
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
}
