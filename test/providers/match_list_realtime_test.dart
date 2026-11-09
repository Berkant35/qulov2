import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/providers/match_list_realtime.dart';

/// Eşleşme listesine uygulanan Realtime olayları (`MatchListNotifier`'dan ayrılan saf kurallar).
const _m1 = MatchModel(
  matchId: 'm1',
  matchedAt: '2026-11-01T10:00:00Z',
  user: MatchUserModel(userId: 'u2'),
  lastMessageSentAt: '2026-11-09T10:00:00Z',
  unreadCount: 1,
);
const _m2 = MatchModel(matchId: 'm2', matchedAt: '2026-11-02T10:00:00Z', user: MatchUserModel(userId: 'u3'));

void main() {
  group('yeni mesaj', () {
    test('karşı taraftan: son mesaj güncellenir, okunmamış +1', () {
      final out = MatchListRealtimeReducer.onNewMessage([_m1, _m2], {
        'match_id': 'm1',
        'sender_id': 'u2',
        'content': 'selam',
        'created_at': '2026-11-09T11:00:00Z',
      }, myId: 'me');

      expect(out.first.lastMessage, 'selam');
      expect(out.first.lastMessageSentAt, '2026-11-09T11:00:00Z');
      expect(out.first.unreadCount, 2);
      expect(out.last, _m2);
    });

    test('kendi mesajım okunmamışı artırmaz', () {
      final out = MatchListRealtimeReducer.onNewMessage([_m1], {
        'match_id': 'm1',
        'sender_id': 'me',
        'created_at': '2026-11-09T11:00:00Z',
      }, myId: 'me');

      expect(out.single.unreadCount, 1);
      expect(out.single.lastMessageSenderId, 'me');
    });

    test('eski / yeniden teslim edilen kayıt yok sayılır (yeniden abonelik sonrası)', () {
      final out = MatchListRealtimeReducer.onNewMessage([_m1], {
        'match_id': 'm1',
        'sender_id': 'u2',
        'created_at': '2026-11-09T10:00:00Z',
      }, myId: 'me');

      expect(out.single, _m1);
    });

    test('match_id yoksa liste değişmez', () {
      expect(MatchListRealtimeReducer.onNewMessage([_m1], {'sender_id': 'u2'}, myId: 'me'), [_m1]);
    });
  });

  group('okundu', () {
    test('karşı tarafın mesajı okununca rozet sıfırlanır', () {
      final out = MatchListRealtimeReducer.onMessageRead([_m1], {
        'match_id': 'm1',
        'sender_id': 'u2',
        'read_at': '2026-11-09T11:00:00Z',
      }, myId: 'me');

      expect(out.single.unreadCount, 0);
    });

    test('kendi mesajımın okunması ya da read_at yokluğu rozeti değiştirmez', () {
      final mine = MatchListRealtimeReducer.onMessageRead([_m1], {
        'match_id': 'm1',
        'sender_id': 'me',
        'read_at': '2026-11-09T11:00:00Z',
      }, myId: 'me');
      final unread = MatchListRealtimeReducer.onMessageRead([_m1], {'match_id': 'm1', 'sender_id': 'u2'}, myId: 'me');

      expect(mine.single.unreadCount, 1);
      expect(unread.single.unreadCount, 1);
    });
  });

  test('çevrimiçi durumu yalnız ilgili kişide değişir', () {
    final out = MatchListRealtimeReducer.onUserStatus([_m1, _m2], {'id': 'u3', 'is_online': true});

    expect(out.first.user!.isOnline, isFalse);
    expect(out.last.user!.isOnline, isTrue);
  });

  group('yeni eşleşme (filtresiz kanal)', () {
    test('katılımcıysam benim', () {
      expect(MatchListRealtimeReducer.isMyNewMatch({'user1_id': 'x', 'user2_id': 'me'}, myId: 'me'), isTrue);
    });

    test('başkalarının eşleşmesi ya da kimliksiz durum yenileme tetiklemez', () {
      expect(MatchListRealtimeReducer.isMyNewMatch({'user1_id': 'x', 'user2_id': 'y'}, myId: 'me'), isFalse);
      expect(MatchListRealtimeReducer.isMyNewMatch({'user1_id': null, 'user2_id': null}, myId: null), isFalse);
    });
  });
}
