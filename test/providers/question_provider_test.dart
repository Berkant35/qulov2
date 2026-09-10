import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';

import '../helpers/fake_repositories.dart';

/// Soru siralama — iyimser guncelleme, geri alma ve basarisizlik sinyali.
///
/// Sunucu tarafi 2026-09-10'a kadar (migration 050) HER gercek siralamayi
/// reddediyordu ve mobil bunu sessizce geri aliyordu (yalniz `dev.log`).
/// Artik `reorderQuestions` `false` donuyor ve ekran kullaniciya soyluyor.
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

Future<ProviderContainer> _container(FakeQuestionRepository fake) async {
  final c = ProviderContainer(
    overrides: [questionRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(c.dispose);
  await c.read(questionProvider.future);
  await c.read(questionProvider.notifier).fetchQuestions();
  return c;
}

List<String> _ids(ProviderContainer c) =>
    c.read(questionProvider).valueOrNull!.map((q) => q.id).toList();

void main() {
  final seed = [_q('q1', 1), _q('q2', 2), _q('q3', 3)];

  test('ilk soruyu sona tasimak — ReorderableListView newIndex duzeltmesi', () async {
    // Sona birakmada ReorderableListView newIndex = length (3) verir; provider
    // bunu 2'ye indirmeli. Yanlis olursa RangeError ya da yanlis sira gider.
    final fake = FakeQuestionRepository(questions: seed);
    final c = await _container(fake);

    final ok = await c.read(questionProvider.notifier).reorderQuestions(0, 3);

    expect(ok, isTrue);
    expect(fake.lastOrderedIds, ['q2', 'q3', 'q1']);
  });

  test('son soruyu basa tasimak — duzeltme uygulanmaz', () async {
    final fake = FakeQuestionRepository(questions: seed);
    final c = await _container(fake);

    await c.read(questionProvider.notifier).reorderQuestions(2, 0);

    expect(fake.lastOrderedIds, ['q3', 'q1', 'q2']);
  });

  test('iyimser guncelleme sunucu cevabindan ONCE gorunur', () async {
    final completer = Completer<void>();
    final fake = FakeQuestionRepository(questions: seed, reorderCompleter: completer);
    final c = await _container(fake);

    final pending = c.read(questionProvider.notifier).reorderQuestions(0, 3);
    await Future<void>.delayed(Duration.zero);

    expect(_ids(c), ['q2', 'q3', 'q1']);
    completer.complete();
    await pending;
  });

  test('basarida state SUNUCUNUN dondugu liste olur', () async {
    // Sunucu yeni order_num'larla doner; iyimser liste onunla degistirilmeli.
    final server = [_q('q2', 1), _q('q3', 2), _q('q1', 3)];
    final fake = FakeQuestionRepository(questions: seed, reorderResponse: server);
    final c = await _container(fake);

    await c.read(questionProvider.notifier).reorderQuestions(0, 3);

    expect(_ids(c), ['q2', 'q3', 'q1']);
    expect(c.read(questionProvider).valueOrNull!.map((q) => q.orderNum), [1, 2, 3]);
  });

  test('BASARISIZLIKTA sira GERI ALINIR ve false doner — ekran bunu gosterir', () async {
    final fake = FakeQuestionRepository(
      questions: seed,
      reorderFailure: const ServerFailure(code: 'SERVER_ERROR', statusCode: 500),
    );
    final c = await _container(fake);

    final ok = await c.read(questionProvider.notifier).reorderQuestions(0, 3);

    expect(ok, isFalse);
    expect(_ids(c), ['q1', 'q2', 'q3']);
  });

  test('liste yuklenemezse ONCEKI bos liste korunur — siralama no-op, cokmez', () async {
    // Bu testin ilk hali `valueOrNull`'un null olacagini varsayiyordu ve YANLISTI:
    // Riverpod hata durumunda onceki veriyi (build'in []'i) koruyor. Asil bulgu
    // ondan cikti — kodda sinir kontrolu yoktu ve bos listede `removeAt(0)`
    // RangeError atiyordu.
    final fake = FakeQuestionRepository(listFailure: const NetworkFailure());
    final c = await _container(fake);
    expect(c.read(questionProvider).hasError, isTrue);
    expect(c.read(questionProvider).valueOrNull, isEmpty);

    final ok = await c.read(questionProvider.notifier).reorderQuestions(0, 1);

    expect(ok, isTrue);
    expect(fake.reorderCallCount, 0);
  });

  test('BAYAT indeks (liste surukleme sirasinda kisaldi) cokertmez, sunucuya gitmez', () async {
    // Indeksler kullanicinin surukledigi ANDAKI listeye gore gelir; arada bir
    // silme/yenileme listeyi kisaltmissa `removeAt` sinir disina duser.
    final fake = FakeQuestionRepository(questions: seed);
    final c = await _container(fake);

    final ok = await c.read(questionProvider.notifier).reorderQuestions(5, 0);

    expect(ok, isTrue);
    expect(fake.reorderCallCount, 0);
    expect(_ids(c), ['q1', 'q2', 'q3']);
  });

  test('ayni yere birakmak sunucuya gitmez', () async {
    // (1, 2): ReorderableListView'da "kendi yerine birak"; duzeltmeden sonra 1 == 1.
    final fake = FakeQuestionRepository(questions: seed);
    final c = await _container(fake);

    final ok = await c.read(questionProvider.notifier).reorderQuestions(1, 2);

    expect(ok, isTrue);
    expect(fake.reorderCallCount, 0);
    expect(_ids(c), ['q1', 'q2', 'q3']);
  });
}
