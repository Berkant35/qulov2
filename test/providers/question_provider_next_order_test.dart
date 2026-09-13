import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/questions/utils/question_text_rules.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../helpers/fake_repositories.dart';

/// Yeni sorunun sira numarasi ve soru metni alt siniri — kurulum kapisinin
/// (en az 2 soru) icindeki akis.
///
/// Sunucu (`question.service.ts` `createQuestion`): `(user_id, order_num)`
/// tekil — cakisma `DUPLICATE_ORDER_NUM`; silmede sira 1..n sikistirilir.
/// `question.validator.ts`: `question_text` en az 5 karakter.
QuestionModel _q(String id, int order) => QuestionModel(
      id: id,
      userId: 'u1',
      orderNum: order,
      questionText: 'Soru $id',
      correctAnswer: 1,
      answer1: 'A',
      answer2: 'B',
      answer3: 'C',
      answer4: 'D',
    );

ProviderContainer _container(FakeQuestionRepository questions, {UserModel? user}) {
  final c = ProviderContainer(overrides: [
    questionRepositoryProvider.overrideWithValue(questions),
    userRepositoryProvider.overrideWithValue(
      FakeUserRepository(user ?? const UserModel(id: 'u1', email: 'u1@qulo.test')),
    ),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('nextOrderNum', () {
    test('liste bu oturumda HIC cekilmemisken sunucudaki sorulara gore hesaplar', () async {
      // Eskiden: state bos (build) → uzunluk + 1 = 1 → mevcut 1. soruyla
      // cakisma → DUPLICATE_ORDER_NUM → "soru kaydedilemedi".
      final c = _container(FakeQuestionRepository(questions: [_q('q1', 1), _q('q2', 2)]));
      await c.read(questionProvider.future);
      expect(c.read(questionProvider).value, isEmpty, reason: 'build hic veri cekmez');

      expect(await c.read(questionProvider.notifier).nextOrderNum(), 3);
    });

    test('hic soru yoksa 1', () async {
      final c = _container(FakeQuestionRepository());

      expect(await c.read(questionProvider.notifier).nextOrderNum(), 1);
    });

    test('liste alinamazsa profildeki soru sayisina duser', () async {
      final c = _container(
        FakeQuestionRepository(listFailure: const NetworkFailure()),
        user: const UserModel(id: 'u1', email: 'u1@qulo.test', questionCount: 2),
      );
      await c.read(userProvider.notifier).fetchMe();

      expect(await c.read(questionProvider.notifier).nextOrderNum(), 3);
    });

    test('liste de profil de yoksa 1', () async {
      final c = _container(FakeQuestionRepository(listFailure: const NetworkFailure()));

      expect(await c.read(questionProvider.notifier).nextOrderNum(), 1);
    });
  });

  group('soru metni alt siniri (sunucu min 5)', () {
    test('5 karakter yeterli, 4 degil', () {
      expect(isQuestionTextLongEnough('Kimim'), isTrue);
      expect(isQuestionTextLongEnough('Kim?'), isFalse);
    });

    test('bosluklar sayilmaz', () {
      expect(isQuestionTextLongEnough('  Kim?  '), isFalse);
    });

    test('bos alan "kisa" uyarisi vermez, yazmaya baslayinca verir', () {
      expect(isQuestionTextTooShort(''), isFalse);
      expect(isQuestionTextTooShort('   '), isFalse);
      expect(isQuestionTextTooShort('Kim'), isTrue);
      expect(isQuestionTextTooShort('Kimsin sen?'), isFalse);
    });
  });
}
