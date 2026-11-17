import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/question_model.dart';

/// Soru sahibi yaniti (`GET /questions/me`) — medya alanlari. Sunucu kapi
/// pasifken anahtarlari HIC gondermez (null degil); mobil bunu "medya yok" okur.
void main() {
  const base = {
    'id': 'q1',
    'user_id': 'u1',
    'order_num': 1,
    'question_text': 'Soru?',
    'correct_answer': 1,
    'answer_1': 'A',
    'answer_2': 'B',
    'answer_3': 'C',
    'answer_4': 'D',
  };

  group('QuestionModel medya alanlari', () {
    test('anahtarlar yoksa hepsi null', () {
      final q = QuestionModel.fromJson(base);

      expect(q.voiceUrl, isNull);
      expect(q.voiceDurationMs, isNull);
      expect(q.imageUrl, isNull);
      expect(q.imageStatus, isNull);
    });

    test('snake_case alanlar okunur', () {
      final q = QuestionModel.fromJson({
        ...base,
        'voice_url': 'https://x/v.m4a',
        'voice_duration_ms': 9000,
        'image_url': 'https://x/i.jpg',
        'image_status': 'approved',
      });

      expect(q.voiceUrl, 'https://x/v.m4a');
      expect(q.voiceDurationMs, 9000);
      expect(q.imageUrl, 'https://x/i.jpg');
      expect(q.imageStatus, QuestionImageStatus.approved);
    });

    test('image_status uc degeri de eslenir', () {
      for (final entry in {
        'pending': QuestionImageStatus.pending,
        'approved': QuestionImageStatus.approved,
        'rejected': QuestionImageStatus.rejected,
      }.entries) {
        expect(
          QuestionModel.fromJson({...base, 'image_status': entry.key}).imageStatus,
          entry.value,
        );
      }
    });

    test('bilinmeyen image_status patlatmaz, null olur', () {
      expect(
        QuestionModel.fromJson({...base, 'image_status': 'quarantined'}).imageStatus,
        isNull,
      );
    });

    test('toJson medya alanlarini geri yazar', () {
      final q = QuestionModel.fromJson({
        ...base,
        'voice_url': 'https://x/v.m4a',
        'voice_duration_ms': 1200,
        'image_status': 'pending',
      });

      final json = q.toJson();

      expect(json['voice_url'], 'https://x/v.m4a');
      expect(json['voice_duration_ms'], 1200);
      expect(json['image_status'], 'pending');
    });
  });

  group('QuestionMediaKind', () {
    test('sunucu yol parcasi (kind) sozlesmesi', () {
      expect(QuestionMediaKind.voice.wireName, 'voice');
      expect(QuestionMediaKind.image.wireName, 'image');
    });
  });
}
