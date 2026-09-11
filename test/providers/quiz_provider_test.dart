import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/repositories/quiz_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';

/// Quiz oturumu — cekirdek mekanik (adayin 2-10 sorusunu coz, hepsi dogruysa
/// eslesme). Sunucu tek dogru kaynak: guc fiyatlari ve kullanilmis gucler
/// sunucudan gelir, istemci hesap yapmaz.
///
/// Cagiran sozlesmesi: `quiz_screen_state_mixin.initMixin` `startSession`'dan
/// ONCE `reset()` cagirir — provider global, onceki quiz'in durumu tasinmasin.
void main() {
  group('startSession', () {
    test('oturum bilgisi ve sunucu fiyatlari yazilir, ilk soru ayni oturumdan cekilir', () async {
      final h = _Harness();

      final result = await h.notifier.startSession('target-1');

      expect(result.isSuccess, isTrue);
      expect(h.repo.startedFor, 'target-1');
      expect(h.state.sessionId, 's1');
      expect(h.state.totalQuestions, 3);
      expect(h.state.purpleCostOf('FIFTY_FIFTY'), 30);
      expect(h.repo.questionFetchedFor, 's1');
      expect(h.state.currentQuestion?.questionNumber, 1);
      expect(h.state.isLoading, isFalse);
    });

    test('hata: failure yazilir, soru istenmez', () async {
      final h = _Harness()
        ..repo.startResult = const Failure(ServerFailure(code: 'QUIZ_ALREADY_ACTIVE', statusCode: 409));

      final result = await h.notifier.startSession('target-1');

      expect(result.isFailure, isTrue);
      expect((h.state.failure as ServerFailure).code, 'QUIZ_ALREADY_ACTIVE');
      expect(h.state.isLoading, isFalse);
      expect(h.repo.questionFetchedFor, isNull);
    });

    test('reset onceki quiz\'in sorusunu, oturumunu ve guc durumunu temizler', () async {
      final h = _Harness();
      await h.notifier.startSession('target-1');
      h.notifier.markPowerUsed('HINT');

      h.notifier.reset();

      expect(h.state.sessionId, isNull);
      expect(h.state.currentQuestion, isNull);
      expect(h.state.usedPowers, isEmpty);
      expect(h.state.powerCosts, isEmpty);
    });
  });

  group('guc durumu', () {
    test('kullanilmis gucler sunucudan gelir — uygulama yeniden acilsa da buton kapali', () async {
      final h = _Harness()..repo.questionResult = Success(_question(2, usedPowers: ['FIFTY_FIFTY']));

      await h.notifier.startSession('target-1');

      expect(h.state.usedPowers, {'FIFTY_FIFTY'});
    });

    test('markPowerUsed mevcutlari koruyarak ekler', () async {
      final h = _Harness()..repo.questionResult = Success(_question(1, usedPowers: ['HINT']));
      await h.notifier.startSession('target-1');

      h.notifier.markPowerUsed('FIFTY_FIFTY');

      expect(h.state.usedPowers, {'HINT', 'FIFTY_FIFTY'});
    });

    test('sonraki soruya gecince onceki sorudaki gucler serbest kalir', () async {
      final h = _Harness();
      await h.notifier.startSession('target-1');
      h.notifier.markPowerUsed('FIFTY_FIFTY');

      h.repo.questionResult = Success(_question(2));
      await h.notifier.fetchCurrentQuestion();

      expect(h.state.currentQuestion?.questionNumber, 2);
      expect(h.state.usedPowers, isEmpty);
    });

    test('bilinmeyen gucun maliyeti 0 — fiyat gosterilmez, istemci hesaplamaz', () async {
      final h = _Harness();
      await h.notifier.startSession('target-1');

      expect(h.state.purpleCostOf('ORACLE'), 0);
      expect(h.state.greenCostOf('ORACLE'), 0);
    });
  });

  group('cevap / kurtarma / pes etme', () {
    test('cevap oturum, sik, guc ve sure ile gider; basari lastAnswer olur', () async {
      final h = _Harness();
      await h.notifier.startSession('target-1');

      await h.notifier.answer(2, powerUsed: 'HINT', timeSpent: 12);

      expect(h.repo.answered, ('s1', 2, 'HINT', 12));
      expect(h.state.lastAnswer?.isCorrect, isTrue);
    });

    test('cevap hatasi state.failure YAZMAZ — rescue popup\'tan paywall\'a gecis bozulmasin', () async {
      final h = _Harness();
      await h.notifier.startSession('target-1');
      h.repo.answerResult = const Failure(ServerFailure(code: 'INSUFFICIENT_DIAMONDS', statusCode: 400));

      final result = await h.notifier.answer(1, powerUsed: 'SKIP');

      expect(result.isFailure, isTrue);
      expect(h.state.failure, isNull);
    });

    test('kurtarma varsayilani SKIP, basari lastAnswer olur', () async {
      final h = _Harness();
      await h.notifier.startSession('target-1');
      h.repo.answerResult = const Success(QuizAnswerResponse(isCorrect: true, canRescue: false));

      await h.notifier.rescue();

      expect(h.repo.rescued, ('s1', 'SKIP'));
      expect(h.state.lastAnswer?.canRescue, isFalse);
    });

    test('pes etme sonucu lastAnswer olur', () async {
      final h = _Harness();
      await h.notifier.startSession('target-1');
      h.repo.answerResult = const Success(QuizAnswerResponse(sessionStatus: 'FAILED'));

      await h.notifier.fail();

      expect(h.repo.failedSession, 's1');
      expect(h.state.lastAnswer?.sessionStatus, 'FAILED');
    });
  });

  group('oturum yokken', () {
    test('cevap/kurtarma/pes/sonuc sunucuya GITMEZ, UnknownFailure doner', () async {
      final h = _Harness();

      final results = [
        await h.notifier.answer(1),
        await h.notifier.rescue(),
        await h.notifier.fail(),
        await h.notifier.getResult(),
      ];

      for (final r in results) {
        expect(r.when(success: (_) => null, failure: (f) => f), isA<UnknownFailure>());
      }
      expect(h.repo.calls, isEmpty);
    });

    test('fetchCurrentQuestion sessizce cikar', () async {
      final h = _Harness();

      await h.notifier.fetchCurrentQuestion();

      expect(h.repo.calls, isEmpty);
    });
  });
}

QuizQuestionModel _question(int number, {List<String> usedPowers = const []}) =>
    QuizQuestionModel(
      sessionId: 's1',
      questionNumber: number,
      totalQuestions: 3,
      questionId: 'q$number',
      questionText: 'Soru $number',
      answers: const [
        QuizAnswerOption(index: 1, text: 'A'),
        QuizAnswerOption(index: 2, text: 'B'),
      ],
      usedPowers: usedPowers,
    );

class _Harness {
  _Harness() {
    container = ProviderContainer(overrides: [quizRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
  }

  final repo = _FakeQuizRepository();
  late final ProviderContainer container;

  QuizNotifier get notifier => container.read(quizProvider.notifier);
  QuizState get state => container.read(quizProvider);
}

class _FakeQuizRepository implements QuizRepository {
  Result<QuizStartResponse> startResult = const Success(QuizStartResponse(
    sessionId: 's1',
    totalQuestions: 3,
    powerCosts: {'FIFTY_FIFTY': SessionPowerCost(purple: 30, green: 0)},
  ));
  Result<QuizQuestionModel> questionResult = Success(_question(1));
  Result<QuizAnswerResponse> answerResult =
      const Success(QuizAnswerResponse(isCorrect: true, nextQuestion: 2));

  final calls = <String>[];
  String? startedFor;
  String? questionFetchedFor;
  (String, int?, String?, int?)? answered;
  (String, String)? rescued;
  String? failedSession;

  @override
  Future<Result<QuizStartResponse>> startSession(String targetId) async {
    calls.add('start');
    startedFor = targetId;
    return startResult;
  }

  @override
  Future<Result<QuizQuestionModel>> getCurrentQuestion(String sessionId) async {
    calls.add('question');
    questionFetchedFor = sessionId;
    return questionResult;
  }

  @override
  Future<Result<QuizAnswerResponse>> answerQuestion(
    String sessionId, {
    int? selectedAnswer,
    String? powerUsed,
    int? timeSpent,
  }) async {
    calls.add('answer');
    answered = (sessionId, selectedAnswer, powerUsed, timeSpent);
    return answerResult;
  }

  @override
  Future<Result<QuizAnswerResponse>> rescueWithSkip(String sessionId, {String powerType = 'SKIP'}) async {
    calls.add('rescue');
    rescued = (sessionId, powerType);
    return answerResult;
  }

  @override
  Future<Result<QuizAnswerResponse>> failSession(String sessionId) async {
    calls.add('fail');
    failedSession = sessionId;
    return answerResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeQuizRepository.${invocation.memberName}');
}
