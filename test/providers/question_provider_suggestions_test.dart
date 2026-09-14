import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';

import '../helpers/fake_repositories.dart';

/// Kurulum kapisi "sihirli doldurma": AI onerilerini soru olarak kaydetme.
///
/// Eskiden mixin `createQuestion` sonucunu hic kontrol etmiyordu — kayit
/// hatasi sessizce yutulup "atandi" analitigi yine atiliyordu. Sira numarasi
/// da liste indeksinden (`start + i`) geliyordu; atlanan oneri bosluk birakiyordu.
Map<String, dynamic> _s(
  String text, {
  List<String> answers = const ['A', 'B', 'C', 'D'],
  String? hint,
  String? category,
}) =>
    {
      'question_text': text,
      'answers': answers,
      'correct_answer': 2,
      if (hint != null) 'hint': hint,
      if (category != null) 'category': category,
    };

Future<ProviderContainer> _container(FakeQuestionRepository questions) async {
  final c = ProviderContainer(overrides: [
    questionRepositoryProvider.overrideWithValue(questions),
    userRepositoryProvider.overrideWithValue(
      FakeUserRepository(const UserModel(id: 'u1', email: 'u1@qulo.test')),
    ),
  ]);
  addTearDown(c.dispose);
  await c.read(questionProvider.future);
  return c;
}

void main() {
  group('createFromSuggestions', () {
    test('gecerli onerileri ardisik order_num ve sunucu govdesiyle kaydeder', () async {
      final fake = FakeQuestionRepository();
      final c = await _container(fake);

      final outcome = await c.read(questionProvider.notifier).createFromSuggestions(
        [_s('Soru bir'), _s('Soru iki', hint: 'ipucu', category: 'music')],
        startOrder: 3,
        locale: 'de',
      );

      expect(outcome.created, 2);
      expect(outcome.failed, 0);
      expect(fake.createdBodies.map((b) => b['order_num']), [3, 4]);

      final first = fake.createdBodies.first;
      expect(first['question_text'], 'Soru bir');
      expect([first['answer_1'], first['answer_2'], first['answer_3'], first['answer_4']],
          ['A', 'B', 'C', 'D']);
      expect(first['correct_answer'], 2);
      expect(first['locale'], 'de');
      expect(first['time_limit'], 30);
      // Sunucu validator'i opsiyonel alanda acik null'u reddeder — anahtar hic olmamali.
      expect(first.containsKey('hint_text'), isFalse);
      expect(first.containsKey('category'), isFalse);

      expect(fake.createdBodies[1]['hint_text'], 'ipucu');
      expect(fake.createdBodies[1]['category'], 'music');
    });

    test('cevabi eksik oneri atlanir ve sirada bosluk birakmaz', () async {
      final fake = FakeQuestionRepository();
      final c = await _container(fake);

      final outcome = await c.read(questionProvider.notifier).createFromSuggestions(
        [_s('Uc cevapli', answers: ['A', 'B', 'C']), _s('Soru iki')],
        startOrder: 1,
        locale: 'tr',
      );

      expect(outcome.created, 1);
      expect(outcome.failed, 0);
      expect(fake.createCallCount, 1, reason: 'eksik oneri sunucuya hic gitmemeli');
      expect(fake.createdBodies.single['order_num'], 1,
          reason: 'eski kod start + i ile 2 uretiyordu');
    });

    test('kayit hatasi sayilir, sonraki kayit ayni sirayi alir', () async {
      final fake = FakeQuestionRepository(createFailures: {0: NetworkFailure()});
      final c = await _container(fake);

      final outcome = await c.read(questionProvider.notifier).createFromSuggestions(
        [_s('Soru bir'), _s('Soru iki')],
        startOrder: 5,
        locale: 'en',
      );

      expect(outcome.created, 1);
      expect(outcome.failed, 1);
      expect(fake.createCallCount, 2);
      expect(fake.createdBodies.single['question_text'], 'Soru iki');
      expect(fake.createdBodies.single['order_num'], 5);
    });

    test('hepsi basarisizsa hicbiri kaydedilmis sayilmaz', () async {
      final fake = FakeQuestionRepository(createFailures: {
        0: NetworkFailure(),
        1: const ServerFailure(code: 'SERVER_ERROR', statusCode: 500),
      });
      final c = await _container(fake);

      final outcome = await c.read(questionProvider.notifier).createFromSuggestions(
        [_s('Soru bir'), _s('Soru iki')],
        startOrder: 1,
        locale: 'en',
      );

      expect(outcome.created, 0);
      expect(outcome.failed, 2);
      expect(fake.createdBodies, isEmpty);
    });
  });
}
