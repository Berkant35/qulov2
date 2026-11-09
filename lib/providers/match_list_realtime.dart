import 'package:qulo_v2/core/services/realtime_channel_group.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Eşleşme listesinin Realtime olaylarını listeye uygulayan saf kurallar
/// (`MatchListNotifier`'dan ayrıldı: notifier yalnız çağırır → eşler → atar).
abstract final class MatchListRealtimeReducer {
  /// Yeni mesaj: son mesaj + sıralama alanları, karşı taraftansa okunmamış +1.
  /// Eldekinden eski ya da aynı zamanlı kayıt (yeniden teslim) yok sayılır.
  static List<MatchModel> onNewMessage(
    List<MatchModel> matches,
    Map<String, dynamic> record, {
    required String? myId,
  }) {
    final matchId = record['match_id'] as String?;
    if (matchId == null) return matches;
    final senderId = record['sender_id'] as String?;
    final createdAt = record['created_at'] as String?;
    return matches.map((m) {
      if (m.matchId != matchId) return m;
      final last = m.lastMessageSentAt;
      if (createdAt != null && last != null && createdAt.compareTo(last) <= 0) return m;
      return m.copyWith(
        lastMessage: record['content'] as String?,
        lastMessageSentAt: createdAt,
        lastMessageSenderId: senderId,
        unreadCount: senderId != myId ? m.unreadCount + 1 : m.unreadCount,
      );
    }).toList();
  }

  /// Karşı tarafın mesajı okundu olarak işaretlendi (ben okudum): rozet sıfırlanır.
  static List<MatchModel> onMessageRead(
    List<MatchModel> matches,
    Map<String, dynamic> record, {
    required String? myId,
  }) {
    final matchId = record['match_id'] as String?;
    if (matchId == null || record['read_at'] == null) return matches;
    if (record['sender_id'] == myId) return matches;
    return matches.map((m) {
      if (m.matchId != matchId || m.unreadCount == 0) return m;
      return m.copyWith(unreadCount: 0);
    }).toList();
  }

  static List<MatchModel> onUserStatus(List<MatchModel> matches, Map<String, dynamic> record) {
    final userId = record['id'] as String?;
    final isOnline = record['is_online'] as bool?;
    if (userId == null || isOnline == null) return matches;
    return matches.map((m) {
      final user = m.user;
      if (user == null || user.userId != userId) return m;
      return m.copyWith(user: user.copyWith(isOnline: isOnline));
    }).toList();
  }

  /// `matches:new` filtresiz: bugün herkese gider, 082 sonrası yalnız katılımcıya.
  static bool isMyNewMatch(Map<String, dynamic> record, {required String? myId}) =>
      myId != null && (record['user1_id'] == myId || record['user2_id'] == myId);
}

/// Olay işleyicileri; `generation` eski kuruluşun olayını ayıklamak içindir.
typedef MatchListRealtimeHandler = void Function(int generation, PostgresChangePayload payload);

/// Eşleşme listesinin dört kanalı. Adlar ve filtreler sözleşmede sabit
/// (`tasks/surum-2.0.18-sozlesmeler.md`): DEĞİŞTİRME — 082/083 policy'leri bunlara göre yazıldı.
List<RealtimeChannel> buildMatchListChannels({
  required SupabaseClient client,
  required List<MatchModel> matches,
  required int generation,
  required RealtimeStatusCallback onStatus,
  required MatchListRealtimeHandler onNewMessage,
  required MatchListRealtimeHandler onMessageRead,
  required MatchListRealtimeHandler onUserStatus,
  required MatchListRealtimeHandler onNewMatch,
}) {
  RealtimeChannel listen(
    String name, {
    required PostgresChangeEvent event,
    required String table,
    required MatchListRealtimeHandler handler,
    PostgresChangeFilter? filter,
  }) =>
      client
          .channel(name)
          .onPostgresChanges(
            event: event,
            schema: 'public',
            table: table,
            filter: filter,
            callback: (payload) => handler(generation, payload),
          )
          .subscribe(onStatus);

  RealtimeChannel newMatches() => listen(
        'matches:new',
        event: PostgresChangeEvent.insert,
        table: 'matches',
        handler: onNewMatch,
      );
  if (matches.isEmpty) return [newMatches()];

  PostgresChangeFilter matchFilter() => PostgresChangeFilter(
        type: PostgresChangeFilterType.inFilter,
        column: 'match_id',
        value: matches.map((m) => m.matchId).toList(),
      );
  final userIds = [for (final m in matches) if (m.user != null) m.user!.userId];

  return [
    listen('matches:messages', event: PostgresChangeEvent.insert, table: 'messages', filter: matchFilter(), handler: onNewMessage),
    listen('matches:read', event: PostgresChangeEvent.update, table: 'messages', filter: matchFilter(), handler: onMessageRead),
    if (userIds.isNotEmpty)
      listen(
        'matches:online',
        event: PostgresChangeEvent.update,
        table: 'users',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.inFilter, column: 'id', value: userIds),
        handler: onUserStatus,
      ),
    newMatches(),
  ];
}
