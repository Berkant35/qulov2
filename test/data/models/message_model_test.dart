import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/message_model.dart';

/// Mesaj modeli iki yoldan dolar: REST (`GET /chat/:id/messages`) ve Realtime
/// (`chat_realtime_mixin` → `MessageModel.fromJson(payload.newRecord)`, yani
/// ham DB satiri). Realtime parse hatasi `try` icinde yutuluyor — model bir
/// satiri parse edemezse mesaj karsi tarafa SESSIZCE gelmez.
///
/// DB semasi (2026-09-11, canli): content/is_image/created_at NOT NULL;
/// read_at/deleted_at/audio_url/audio_duration_seconds nullable.
void main() {
  group('fromJson', () {
    test('realtime DB satiri (tum kolonlar, nullable\'lar null) parse edilir', () {
      final message = MessageModel.fromJson(const {
        'id': '6c1b2f8e-0000-4000-8000-000000000001',
        'match_id': '6c1b2f8e-0000-4000-8000-0000000000aa',
        'sender_id': '6c1b2f8e-0000-4000-8000-0000000000bb',
        'content': 'selam',
        'is_image': false,
        'read_at': null,
        'created_at': '2026-09-11T10:00:00.123456+00:00',
        'deleted_at': null,
        'audio_url': null,
        'audio_duration_seconds': null,
      });

      expect(message.content, 'selam');
      expect(message.isDeleted, isFalse);
      expect(message.isAudio, isFalse);
      expect(message.reactions, isNull);
      expect(message.createdAt, '2026-09-11T10:00:00.123456+00:00');
    });

    test('sesli mesaj alanlari tasinir', () {
      final message = MessageModel.fromJson(const {
        'id': 'm1',
        'match_id': 'x',
        'sender_id': 'u1',
        'content': '',
        'is_image': false,
        'audio_url': 'https://cdn.example/a.m4a',
        'audio_duration_seconds': 7,
      });

      expect(message.isAudio, isTrue);
      expect(message.audioDurationSeconds, 7);
    });

    test('is_image gelmezse false, bilinmeyen kolonlar yok sayilir', () {
      final message = MessageModel.fromJson(const {
        'id': 'm1',
        'match_id': 'x',
        'sender_id': 'u1',
        'content': 'selam',
        'yeni_kolon': 'sunucu ekledi',
      });

      expect(message.isImage, isFalse);
    });

    test('tepkiler parse edilir', () {
      final message = MessageModel.fromJson(const {
        'id': 'm1',
        'match_id': 'x',
        'sender_id': 'u1',
        'content': 'selam',
        'reactions': [
          {'emoji': '❤️', 'user_id': 'u2'},
        ],
      });

      expect(message.reactions, [const MessageReaction(emoji: '❤️', userId: 'u2')]);
    });
  });

  group('copyWith (chat_provider yerel guncellemeleri)', () {
    const original = MessageModel(
      id: 'm1',
      matchId: 'x',
      senderId: 'u1',
      content: 'selam',
      isImage: true,
      readAt: '2026-09-11T10:01:00Z',
      audioUrl: 'https://cdn.example/a.m4a',
      audioDurationSeconds: 7,
      reactions: [MessageReaction(emoji: '🔥', userId: 'u2')],
      createdAt: '2026-09-11T10:00:00Z',
    );

    test('tepki guncellemesi diger TUM alanlari korur', () {
      final updated = original.copyWith(reactions: const []);

      expect(updated.reactions, isEmpty);
      expect(
        (updated.id, updated.matchId, updated.senderId, updated.content, updated.isImage,
            updated.readAt, updated.deletedAt, updated.audioUrl, updated.audioDurationSeconds,
            updated.createdAt),
        ('m1', 'x', 'u1', 'selam', true, '2026-09-11T10:01:00Z', null,
            'https://cdn.example/a.m4a', 7, '2026-09-11T10:00:00Z'),
      );
    });

    test('silme isareti tepkileri ve icerigi korur', () {
      final deleted = original.copyWith(deletedAt: '2026-09-11T10:05:00Z');

      expect(deleted.isDeleted, isTrue);
      expect(deleted.reactions, original.reactions);
      expect(deleted.content, 'selam');
    });

    test('arguman verilmezse degisiklik yok', () {
      final same = original.copyWith();

      expect((same.reactions, same.deletedAt), (original.reactions, null));
    });
  });
}
