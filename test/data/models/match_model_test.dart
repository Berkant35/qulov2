import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/match_model.dart';

/// Eslesme listesi modeli. Varsayilanli alanlar sunucu gondermese de listeyi
/// cokertmemeli (`as T? ?? varsayilan`); medya (foto/ses) yalnizca IKI TARAF
/// da actiginda acik.
void main() {
  group('fromJson', () {
    test('asgari satir: varsayilanlar devreye girer, kullanici null olabilir', () {
      final match = MatchModel.fromJson(const {
        'match_id': 'm1',
        'matched_at': '2026-09-11T10:00:00Z',
      });

      expect(match.unreadCount, 0);
      expect(match.mediaEnabledByUser1, isFalse);
      expect(match.mediaEnabledByUser2, isFalse);
      expect(match.user, isNull);
      expect(match.lastMessage, isNull);
    });

    test('dolu satir: son mesaj, okunmamis ve karsi taraf tasinir', () {
      final match = MatchModel.fromJson(const {
        'match_id': 'm1',
        'matched_at': '2026-09-11T10:00:00Z',
        'user': {
          'user_id': 'u2',
          'name': 'Ayse',
          'age': 27,
          'city': 'Istanbul',
          'photos': ['https://cdn.example/p1.jpg'],
          'is_online': true,
          'last_seen': '2026-09-11T09:59:00Z',
        },
        'last_message': 'naber',
        'last_message_sent_at': '2026-09-11T10:02:00Z',
        'last_message_sender_id': 'u2',
        'unread_count': 3,
      });

      expect(match.user?.name, 'Ayse');
      expect(match.user?.isOnline, isTrue);
      expect(match.user?.photos, ['https://cdn.example/p1.jpg']);
      expect(match.unreadCount, 3);
      expect(match.lastMessageSenderId, 'u2');
    });

    test('kullanicida is_online gelmezse cevrimdisi sayilir', () {
      final user = MatchUserModel.fromJson(const {'user_id': 'u2'});

      expect(user.isOnline, isFalse);
      expect(user.photos, isNull);
    });

    test('unread_count ondalikli gelse de tam sayiya cevrilir', () {
      final match = MatchModel.fromJson(const {
        'match_id': 'm1',
        'matched_at': '2026-09-11T10:00:00Z',
        'unread_count': 2.0,
      });

      expect(match.unreadCount, 2);
    });
  });

  group('isMediaEnabled — iki taraf da acmali', () {
    for (final (a, b, expected) in [
      (false, false, false),
      (true, false, false),
      (false, true, false),
      (true, true, true),
    ]) {
      test('user1=$a, user2=$b → $expected', () {
        final match = MatchModel(
          matchId: 'm1',
          matchedAt: '2026-09-11T10:00:00Z',
          mediaEnabledByUser1: a,
          mediaEnabledByUser2: b,
        );

        expect(match.isMediaEnabled, expected);
      });
    }
  });
}
