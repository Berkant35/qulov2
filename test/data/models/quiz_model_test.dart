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

  group('soru basina sure + ilk quiz ikinci sansi (sunucu 2026-10-04)', () {
    QuizQuestionModel question({int? remaining, int limit = 30}) => QuizQuestionModel.fromJson({
          'session_id': 's1',
          'question_number': 1,
          'total_questions': 3,
          'question_id': 'q1',
          'question_text': 'Soru',
          'answers': const [],
          'time_limit_seconds': limit,
          if (remaining != null) 'remaining_seconds': remaining,
        });

    test('eski sunucu (remaining_seconds yok) → tam sure', () {
      expect(question().startSeconds, 30);
    });

    test('yeniden acilis: sayac kalan sureden baslar', () {
      expect(question(remaining: 12).startSeconds, 12);
    });

    test('taze soruda sunucu toleransi gosterilmez — soru suresini asmaz', () {
      expect(question(remaining: 34).startSeconds, 30);
    });

    test('sure bitmisse en az 1 sn — ilk tikte TIME_UP akisi calisir', () {
      expect(question(remaining: 0).startSeconds, 1);
    });

    test('yanlis cevap free_second_chance, kurtarma free_second_chance_used tasir', () {
      final wrong = QuizAnswerResponse.fromJson(const {
        'is_correct': false,
        'can_rescue': true,
        'free_second_chance': true,
      });
      expect(wrong.freeSecondChance, isTrue);

      final rescued = QuizAnswerResponse.fromJson(const {
        'is_correct': true,
        'free_second_chance_used': true,
      });
      expect(rescued.freeSecondChanceUsed, isTrue);
    });
  });

  group('QuizQuestionModel — medya alanlari (sozlesme: kapi pasifken anahtar YOK)', () {
    const base = {
      'session_id': 's1',
      'question_number': 1,
      'total_questions': 2,
      'question_id': 'q1',
      'question_text': 'Soru?',
      'answers': [
        {'index': 1, 'text': 'A'},
      ],
    };

    test('anahtarlar yoksa varsayilan: null / null / null / 0', () {
      final q = QuizQuestionModel.fromJson(base);

      expect(q.voiceUrl, isNull);
      expect(q.voiceDurationMs, isNull);
      expect(q.imageUrl, isNull);
      expect(q.mediaExtraSeconds, 0);
    });

    test('anahtarlar varsa okunur', () {
      final q = QuizQuestionModel.fromJson({
        ...base,
        'voice_url': 'https://x/v.m4a',
        'voice_duration_ms': 7300,
        'image_url': 'https://x/i.jpg',
        'media_extra_seconds': 11,
      });

      expect(q.voiceUrl, 'https://x/v.m4a');
      expect(q.voiceDurationMs, 7300);
      expect(q.imageUrl, 'https://x/i.jpg');
      expect(q.mediaExtraSeconds, 11);
    });

    test('media_extra_seconds null gelirse 0', () {
      expect(
        QuizQuestionModel.fromJson({...base, 'media_extra_seconds': null}).mediaExtraSeconds,
        0,
      );
    });
  });

  /// Sayaç tutma (2.0.19): sunucu son anı = ilk gösterim + taban (L) + media_extra (E) + tolerans;
  /// `remaining_seconds` (R) E'yi İÇERİR. Tutma ≤ R − L ⇒ tutma + L ≤ R: sayaç son anı geçmez.
  group('mediaHoldSeconds — sayaç medya için ne kadar bekler', () {
    QuizQuestionModel media({int? remaining, int extra = 5, bool voice = true, bool image = false}) =>
        QuizQuestionModel.fromJson({
          'session_id': 's1',
          'question_number': 1,
          'total_questions': 3,
          'question_id': 'q1',
          'question_text': 'Soru',
          'answers': const [],
          'time_limit_seconds': 10,
          'media_extra_seconds': extra,
          if (remaining != null) 'remaining_seconds': remaining,
          if (voice) 'voice_url': 'https://x/v.m4a',
          if (image) 'image_url': 'https://x/i.jpg',
        });

    test('media_extra_seconds 0 → tutma yok (eski davranış)', () {
      expect(media(extra: 0, remaining: 10).mediaHoldSeconds, 0);
    });

    test('taze soru (R = L + E) → tutma = E, sayaç tabandan başlar', () {
      final q = media(remaining: 15);
      expect(q.mediaHoldSeconds, 5);
      expect(q.startSeconds, 10);
    });

    test('tolerans dahil taze soru (R = L + E + 2) → tutma E ile sınırlı', () {
      expect(media(remaining: 17).mediaHoldSeconds, 5);
    });

    test('remaining_seconds yok (eski yanıt biçimi) → tutma = E', () {
      expect(media().mediaHoldSeconds, 5);
    });

    test('yeniden açılış (R = L + 2) → tutma R − L = 2', () {
      expect(media(remaining: 12).mediaHoldSeconds, 2);
    });

    test('yeniden açılış (R < L) → tutma yok, sayaç kalan süreden', () {
      final q = media(remaining: 7);
      expect(q.mediaHoldSeconds, 0);
      expect(q.startSeconds, 7);
    });

    test('medya URL yoksa (imza alınamadı) → tutma yok', () {
      expect(media(remaining: 15, voice: false).mediaHoldSeconds, 0);
    });

    test('yalnız görsel → tutma = E', () {
      expect(media(remaining: 15, voice: false, image: true).mediaHoldSeconds, 5);
    });
  });
}
