import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';

/// Quiz modelleri — sunucu `quiz.service.ts` yanitlari. Soru satirinda
/// opsiyonel alanlar yoksa guvenli varsayilana duser; `used_powers` guc
/// butonlarinin durumunu yeniden acilista kurar (`quiz_provider`).
void main() {
  group('QuizQuestionModel.fromJson', () {
    test('tam yanit parse edilir; sik indeksi 1-tabanli (sunucu {index: 1, ...})', () {
      final q = QuizQuestionModel.fromJson(const {
        'session_id': 's1',
        'question_number': 2,
        'total_questions': 5,
        'question_id': 'q2',
        'question_text': 'En sevdigim sehir?',
        'answers': [
          {'index': 1, 'text': 'Izmir'},
          {'index': 2, 'text': 'Ankara'},
        ],
        'has_hint': true,
        'time_limit_seconds': 60,
        'used_powers': ['HALF'],
      });

      expect(q.questionNumber, 2);
      expect(q.answers.map((a) => a.index), [1, 2]);
      expect(q.hasHint, isTrue);
      expect(q.timeLimitSeconds, 60);
      expect(q.usedPowers, ['HALF']);
    });

    test('opsiyonel alanlar yoksa: ipucu yok, 30 sn, kullanilmis guc yok', () {
      final q = QuizQuestionModel.fromJson(const {
        'session_id': 's1',
        'question_number': 1,
        'total_questions': 3,
        'question_id': 'q1',
        'question_text': 'Soru',
        'answers': [
          {'index': 1, 'text': 'A'},
        ],
      });

      expect(q.hasHint, isFalse);
      expect(q.timeLimitSeconds, 30);
      expect(q.usedPowers, isEmpty);
    });
  });

  group('QuizStartResponse / QuizAnswerResponse', () {
    test('baslangic yaniti oturumu ve oturum-carpanli guc fiyatlarini tasir', () {
      final start = QuizStartResponse.fromJson(const {
        'session_id': 's1',
        'total_questions': 4,
        'power_costs': {
          'SKIP': {'purple': 50, 'green': 60},
        },
      });

      expect(start.sessionId, 's1');
      expect(start.powerCosts['SKIP'], const SessionPowerCost(purple: 50, green: 60));
    });

    test('power_costs gelmezse bos — istemci fiyat UYDURMAZ (gosterim 0 → gizli)', () {
      final start = QuizStartResponse.fromJson(const {'session_id': 's1', 'total_questions': 2});

      expect(start.powerCosts, isEmpty);
    });

    test('cevap yaniti tum alanlari opsiyonel — gucun sonucu ve eslesme tasinir', () {
      final answer = QuizAnswerResponse.fromJson(const {
        'is_correct': true,
        'matched': true,
        'session_status': 'COMPLETED',
        'badge': 'perfect',
        'power_result': {'removed_indices': [2, 4]},
      });

      expect(answer.matched, isTrue);
      expect(answer.sessionStatus, 'COMPLETED');
      expect(answer.powerResult?['removed_indices'], [2, 4]);
    });

    test('bos cevap yaniti cokmez', () {
      final answer = QuizAnswerResponse.fromJson(const <String, dynamic>{});

      expect(answer.isCorrect, isNull);
      expect(answer.canRescue, isNull);
    });
  });
}
