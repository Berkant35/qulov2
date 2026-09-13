import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/chat/utils/chat_question_form.dart';

/// Sohbet sorusu olusturma — elmas harcayan bir akis (guc engeli, kilit).
/// Sozlesme qulo-server `chat-question.validator.ts` `createChatQuestionSchema`.
bool _valid({
  String question = 'En sevdigim renk?',
  int count = 2,
  String a = 'Mavi',
  String b = 'Yesil',
  String c = '',
  String d = '',
  String correct = 'A',
}) =>
    isChatQuestionStep1Valid(
      questionText: question,
      optionCount: count,
      optionA: a,
      optionB: b,
      optionC: c,
      optionD: d,
      correctOption: correct,
    );

Map<String, dynamic> _payload({
  int count = 2,
  String c = '',
  String d = '',
  String hint = '',
  String? mediaUrl,
  String? mediaType,
  bool powerBlock = false,
}) =>
    buildChatQuestionPayload(
      questionText: '  En sevdigim renk?  ',
      optionCount: count,
      optionA: ' Mavi ',
      optionB: 'Yesil',
      optionC: c,
      optionD: d,
      correctOption: 'A',
      timeLimitSeconds: 45,
      hintText: hint,
      rewardMediaUrl: mediaUrl,
      rewardMediaType: mediaType,
      hasUnmatchRisk: true,
      hasChatLock: false,
      hasPowerBlock: powerBlock,
    );

void main() {
  group('isChatQuestionStep1Valid — sunucu kurallari', () {
    test('gecerli 2 sikli soru', () => expect(_valid(), isTrue));

    test('soru en az 3 karakter — bosluklar sayilmaz', () {
      expect(_valid(question: 'ab'), isFalse);
      expect(_valid(question: '  ab  '), isFalse);
      expect(_valid(question: 'abc'), isTrue);
    });

    test('A ve B dolu olmali', () {
      expect(_valid(a: '  '), isFalse);
      expect(_valid(b: ''), isFalse);
    });

    test('4 sikta C ve D zorunlu', () {
      expect(_valid(count: 4, c: 'Kirmizi'), isFalse);
      expect(_valid(count: 4, c: 'Kirmizi', d: 'Mor', correct: 'D'), isTrue);
    });

    test('2 sikta dogru cevap C/D olamaz — sunucu 400 donerdi', () {
      expect(_valid(correct: 'C'), isFalse);
      expect(_valid(correct: 'D'), isFalse);
      expect(_valid(correct: 'B'), isTrue);
    });
  });

  group('buildChatQuestionPayload — sozlesme alanlari', () {
    test('zorunlu alanlar kirpilmis, guc engeli use_power_block adiyla', () {
      final p = _payload(powerBlock: true);

      expect(p, {
        'question_text': 'En sevdigim renk?',
        'option_count': 2,
        'option_a': 'Mavi',
        'option_b': 'Yesil',
        'correct_option': 'A',
        'time_limit_seconds': 45,
        'has_unmatch_risk': true,
        'has_chat_lock': false,
        'use_power_block': true,
      });
    });

    test('2 sikta C/D anahtari HIC gitmez', () {
      final p = _payload(c: 'artik', d: 'veri');

      expect(p.containsKey('option_c'), isFalse);
      expect(p.containsKey('option_d'), isFalse);
    });

    test('4 sikta C ve D kirpilarak gider', () {
      final p = _payload(count: 4, c: ' Kirmizi ', d: 'Mor ');

      expect((p['option_c'], p['option_d']), ('Kirmizi', 'Mor'));
    });

    test('bos/bosluk ipucu gonderilmez, dolu ipucu kirpilir', () {
      expect(_payload(hint: '   ').containsKey('hint_text'), isFalse);
      expect(_payload(hint: ' gokyuzu ')['hint_text'], 'gokyuzu');
    });

    test('odul medyasi url ile birlikte turu de gider; yoksa ikisi de yok', () {
      final withMedia = _payload(mediaUrl: 'https://cdn.example/a.jpg', mediaType: 'image');
      final without = _payload();

      expect((withMedia['reward_media_url'], withMedia['reward_media_type']),
          ('https://cdn.example/a.jpg', 'image'));
      expect(without.keys, isNot(contains('reward_media_url')));
      expect(without.keys, isNot(contains('reward_media_type')));
    });
  });
}
