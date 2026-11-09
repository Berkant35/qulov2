import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/services/realtime_channel_group.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';

/// Chat ekraninin realtime abonelikleri: mesaj insert, typing broadcast,
/// medya istegi degisiklikleri.
///
/// `ChatScreenMixin`'den ayrildi: tek dosya 677 satira cikti (limit 300).
/// Ayni bolme deseni `ChatQuestionPowerMixin` / `QuizPowerMixin` tarafinda da var.
mixin ChatRealtimeMixin on ChatScreenMixin {
  RealtimeChannelGroup? _realtime;
  RealtimeChannel? _typingChannel;
  Timer? _mediaDebounce;
  Timer? _typingDebounce;
  bool isOtherTyping = false;

  // ─── Lifecycle Kancalari ───

  /// Kanal adlari (`chat:`, `typing:`, `media:` + matchId) sozlesmede sabit.
  /// Kullanici token'i, kopuklukta / token yenilenince yeniden kurulum
  /// [RealtimeChannelGroup]'ta.
  @override
  void subscribeRealtime() {
    final realtime = RealtimeChannelGroup(
      auth: ref.read(realtimeAuthManagerProvider),
      userId: ref.read(authProvider).userId ?? '',
      build: (_, onStatus) => [
        _subscribeMessages(onStatus),
        _typingChannel = _subscribeTyping(onStatus),
        _subscribeMediaRequests(onStatus),
      ],
    );
    _realtime = realtime;
    unawaited(realtime.start());
  }

  @override
  void disposeRealtime() {
    _realtime?.dispose();
    _realtime = null;
    _typingChannel = null;
    _mediaDebounce?.cancel();
    _typingDebounce?.cancel();
  }

  // ─── Realtime ───

  RealtimeChannel _subscribeMessages(RealtimeStatusCallback onStatus) {
    final myId = ref.read(authProvider).userId;
    return Supabase.instance.client
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
        .subscribe(onStatus);
  }

  RealtimeChannel _subscribeTyping(RealtimeStatusCallback onStatus) {
    final myId = ref.read(authProvider).userId;
    return Supabase.instance.client
        .channel('typing:${widget.matchId}')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (disposed) return;
            final senderId = payload['user_id'] as String?;
            if (senderId != null && senderId != myId) {
              setState(() => isOtherTyping = true);
              _typingDebounce?.cancel();
              _typingDebounce = Timer(AppDurations.typingIndicator, () {
                if (mounted) setState(() => isOtherTyping = false);
              });
            }
          },
        )
        .subscribe(onStatus);
  }

  RealtimeChannel _subscribeMediaRequests(RealtimeStatusCallback onStatus) {
    return Supabase.instance.client
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
            _mediaDebounce?.cancel();
            _mediaDebounce = Timer(AppDurations.mediaRequestDebounce, () {
              ref.read(chatProvider(widget.matchId).notifier).loadMediaStatus();
            });
          },
        )
        .subscribe(onStatus);
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
