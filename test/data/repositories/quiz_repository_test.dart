import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/quiz_service.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/models/quiz_summary_model.dart';
import 'package:qulo_v2/data/repositories/quiz_repository.dart';

/// Quiz repository'si — eşleşmenin ve güç harcamasının geçtiği yol.
///
/// Sunucu sözleşmesi (`quiz.validator.ts:7-16`):
///   selected_answer  → int, **1-4**, opsiyonel
///   power_used       → ORACLE | HALF | SKIP | SKIP_ALL | TIME_EXTEND | HINT, opsiyonel
///   time_spent       → int, 0-120, opsiyonel
///   ve `.refine(...)`: **ikisinden en az biri zorunlu**.
///
/// Şık indeksinin 1-tabanlı olması doğrulandı: sunucu `{index: 1, text: ...}`
/// üretiyor (`quiz.service.ts:286`), mobil o değeri geri gönderiyor — kendi
/// 0-tabanlı indeksini üretmiyor.
class _FakeQuizService implements QuizService {
  _FakeQuizService({this.error});

  final DioException? error;

  Map<String, dynamic>? lastStartPayload;
  Map<String, dynamic>? lastAnswerPayload;
  Map<String, dynamic>? lastRescuePayload;
  String? lastSessionId;
  int answerCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<QuizStartResponse> startSession(Map<String, dynamic> data) async {
    lastStartPayload = data;
    if (error != null) throw _err;
    return const QuizStartResponse(sessionId: 's1', totalQuestions: 3);
  }

  @override
  Future<QuizQuestionModel> getCurrentQuestion(String sessionId) async {
    lastSessionId = sessionId;
    if (error != null) throw _err;
    return const QuizQuestionModel(
      sessionId: 's1',
      questionNumber: 1,
      totalQuestions: 3,
      questionId: 'q1',
      questionText: 'Soru?',
      answers: [QuizAnswerOption(index: 1, text: 'A')],
    );
  }

  @override
  Future<QuizAnswerResponse> answerQuestion(String sessionId, Map<String, dynamic> data) async {
    answerCallCount++;
    lastSessionId = sessionId;
    lastAnswerPayload = data;
    if (error != null) throw _err;
    return const QuizAnswerResponse(isCorrect: true, nextQuestion: 2);
  }

  @override
  Future<QuizAnswerResponse> rescueWithSkip(String sessionId, Map<String, dynamic> data) async {
    lastSessionId = sessionId;
    lastRescuePayload = data;
    if (error != null) throw _err;
    return const QuizAnswerResponse(sessionStatus: 'active');
  }

  @override
  Future<QuizAnswerResponse> failSession(String sessionId) async {
    lastSessionId = sessionId;
    if (error != null) throw _err;
    return const QuizAnswerResponse(sessionStatus: 'failed');
  }

  @override
  Future<QuizResultModel> getSessionResult(String sessionId) async {
    lastSessionId = sessionId;
    if (error != null) throw _err;
    return const QuizResultModel(
      sessionId: 's1',
      solverId: 'u1',
      targetId: 'u2',
      status: 'passed',
      currentQ: 3,
      totalQuestions: 3,
      expiresAt: '2026-09-09T00:00:00.000Z',
      answers: [],
    );
  }

  @override
  Future<QuizSummaryModel?> getMatchQuizSummary(String matchId) async {
    lastSessionId = matchId;
    if (error != null) throw _err;
    return null;
  }
}

DioException _dio(DioExceptionType type, {int? status, dynamic body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: status,
              data: body,
            ),
    );

void main() {
  group('startSession', () {
    test('target_id payload olarak gonderilir', () async {
      final fake = _FakeQuizService();

      await QuizRepository(fake).startSession('u2');

      expect(fake.lastStartPayload, {'target_id': 'u2'});
    });

    test('sunucu hata kodu ServerFailure olarak tasinir', () async {
      // Ornek: karsi tarafin sorusu kalmamis ya da oturum acik.
      final fake = _FakeQuizService(
        error: _dio(DioExceptionType.badResponse,
            status: 409, body: {'error': {'code': 'SESSION_ALREADY_ACTIVE'}}),
      );

      final result = await QuizRepository(fake).startSession('u2');

      final failure = result.when(success: (_) => null, failure: (f) => f);
      expect((failure as ServerFailure).code, 'SESSION_ALREADY_ACTIVE');
      expect(failure.statusCode, 409);
    });
  });

  group('answerQuestion — sozlesme', () {
    test('yalnizca selected_answer: power_used ve time_spent anahtarlari YOK', () async {
      final fake = _FakeQuizService();

      await QuizRepository(fake).answerQuestion('s1', selectedAnswer: 3);

      expect(fake.lastAnswerPayload, {'selected_answer': 3});
      expect(fake.lastSessionId, 's1');
    });

    test('guc kullanimi: power_used gonderilir, selected_answer YOK', () async {
      // Guc kullanirken sik secilmiyor; sunucu `.refine` ile ikisinden birini
      // zorunlu tuttugu icin bu payload gecerli.
      final fake = _FakeQuizService();

      await QuizRepository(fake).answerQuestion('s1', powerUsed: 'ORACLE');

      expect(fake.lastAnswerPayload, {'power_used': 'ORACLE'});
    });

    test('time_spent verilince eklenir, verilmeyince hic gonderilmez', () async {
      final withTime = _FakeQuizService();
      await QuizRepository(withTime).answerQuestion('s1', selectedAnswer: 2, timeSpent: 14);
      expect(withTime.lastAnswerPayload!['time_spent'], 14);

      final withoutTime = _FakeQuizService();
      await QuizRepository(withoutTime).answerQuestion('s1', selectedAnswer: 2);
      expect(withoutTime.lastAnswerPayload!.containsKey('time_spent'), isFalse);
    });

    test('SOZLESME RISKI: ikisi de null ise payload BOS kalir ve sunucu 400 doner', () async {
      // Repository bunu engellemiyor; sunucudaki `.refine(...)` reddediyor.
      // Bugun guvendeyiz cunku iki cagri yeri de birini veriyor
      // (quiz_answer_mixin.dart:57 sik, quiz_power_mixin.dart:44 guc).
      // Bu test o sessiz varsayimi gorunur kiliyor: biri `answer(null)` yazarsa
      // burasi bos payload uretir ve hata calisma zamaninda ortaya cikar.
      final fake = _FakeQuizService();

      await QuizRepository(fake).answerQuestion('s1');

      expect(fake.lastAnswerPayload, isEmpty);
    });

    test('hata durumunda servis TAM BIR KEZ cagrilir — sessiz tekrar yok', () async {
      // Guc kullanimi elmas harciyor; gizli bir retry cift harcama demek.
      final fake = _FakeQuizService(error: _dio(DioExceptionType.receiveTimeout));

      final result = await QuizRepository(fake).answerQuestion('s1', powerUsed: 'HALF');

      expect(result.when(success: (_) => null, failure: (f) => f), isA<TimeoutFailure>());
      expect(fake.answerCallCount, 1);
    });
  });

  group('rescueWithSkip', () {
    test('varsayilan guc tipi SKIP', () async {
      final fake = _FakeQuizService();

      await QuizRepository(fake).rescueWithSkip('s1');

      expect(fake.lastRescuePayload, {'power_type': 'SKIP'});
    });

    test('verilen guc tipi oldugu gibi gecer', () async {
      final fake = _FakeQuizService();

      await QuizRepository(fake).rescueWithSkip('s1', powerType: 'SKIP_ALL');

      expect(fake.lastRescuePayload, {'power_type': 'SKIP_ALL'});
    });

    test('yetersiz bakiye hatasi ServerFailure olarak tasinir', () async {
      // Paywall akisi bu koda dayaniyor.
      final fake = _FakeQuizService(
        error: _dio(DioExceptionType.badResponse,
            status: 402, body: {'error': {'code': 'INSUFFICIENT_DIAMONDS'}}),
      );

      final result = await QuizRepository(fake).rescueWithSkip('s1');

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'INSUFFICIENT_DIAMONDS');
    });
  });

  group('diger uc noktalar', () {
    test('getCurrentQuestion session id ile cagrilir ve modeli sarar', () async {
      final fake = _FakeQuizService();

      final result = await QuizRepository(fake).getCurrentQuestion('s9');

      expect(fake.lastSessionId, 's9');
      expect(result.when(success: (d) => d.questionId, failure: (_) => null), 'q1');
    });

    test('getMatchQuizSummary null donebilir — ozet yoksa hata degil', () async {
      // Eslesmede henuz ozet olmayabilir; bu bir Failure degil, bos Success.
      final result = await QuizRepository(_FakeQuizService()).getMatchQuizSummary('m1');

      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d, failure: (_) => null), isNull);
    });

    test('failSession ag hatasinda Failure doner', () async {
      final fake = _FakeQuizService(error: _dio(DioExceptionType.connectionError));

      final result = await QuizRepository(fake).failSession('s1');

      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });
  });
}
