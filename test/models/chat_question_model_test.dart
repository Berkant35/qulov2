import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';

/// Sunucunun kalıcı yazdığı güç sonuçları: `eliminated_options` (HALF) ve
/// `oracle_suggested_option` (ORACLE). Ekran yeniden açıldığında `removedOptions`
/// ve `suggestedOption` buradan hidre edilir — yoksa güç "kullanıldı" görünür ama
/// etkisi kaybolur (ödenen güç boşa gider).
void main() {
  group('ChatQuestionModel güç sonuçları', () {
    test('eliminated_options listesini parse eder', () {
      final q = ChatQuestionModel.fromJson(
        _baseJson()..['eliminated_options'] = ['B', 'D'],
      );
      expect(q.eliminatedOptions, ['B', 'D']);
    });

    test('oracle_suggested_option parse edilir', () {
      final q = ChatQuestionModel.fromJson(
        _baseJson()..['oracle_suggested_option'] = 'C',
      );
      expect(q.oracleSuggestedOption, 'C');
    });

    test('alanlar yoksa null — güç kullanılmamış', () {
      final q = ChatQuestionModel.fromJson(_baseJson());
      expect(q.eliminatedOptions, isNull);
      expect(q.oracleSuggestedOption, isNull);
    });
  });
}

Map<String, dynamic> _baseJson() => {
      'id': 'q1',
      'match_id': 'm1',
      'sender_id': 'u2',
      'question_text': 'En sevdiğim şehir?',
      'option_a': 'İzmir',
      'option_b': 'Ankara',
      'option_c': 'Bursa',
      'option_d': 'Van',
      'option_count': 4,
      'created_at': '2026-09-04T10:00:00Z',
    };
