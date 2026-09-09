import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/question_service.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/repositories/question_repository.dart';

/// Soru repository'si — profilin görünürlüğü buna bağlı (min 2 soru kuralı).
///
/// İki sözleşme burada donduruluyor:
/// 1. `createQuestion`/`updateQuestion` map'i **olduğu gibi** iletir. `time_limit`
///    bunun içinden geçiyor ve değeri artık sunucuda economy config'ten
///    doğrulanıyor (2026-09-09'da sabit `TIME_PRESETS` kapısı kaldırıldı) —
///    istemci araya girip değer kırpmamalı.
/// 2. `reorderQuestions` payload'ı `{'order': [...]}`; sunucu şeması
///    `order: z.array(uuid).min(1).max(20)`.
class _FakeQuestionService implements QuestionService {
  _FakeQuestionService({this.error, this.questions});

  final DioException? error;
  final List<QuestionModel>? questions;

  Map<String, dynamic>? lastCreate;
  Map<String, dynamic>? lastUpdate;
  Map<String, dynamic>? lastReorder;
  int? lastOrderNum;
  int createCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  QuestionModel get _q => const QuestionModel(
        id: 'q1', userId: 'u1', orderNum: 1, questionText: 'Soru?',
        correctAnswer: 1, answer1: 'A', answer2: 'B', answer3: 'C', answer4: 'D',
      );

  @override
  Future<List<QuestionModel>> getMyQuestions() async {
    if (error != null) throw _err;
    return questions ?? const [];
  }

  @override
  Future<QuestionModel> createQuestion(Map<String, dynamic> data) async {
    createCallCount++;
    lastCreate = data;
    if (error != null) throw _err;
    return _q;
  }

  @override
  Future<QuestionModel> updateQuestion(int orderNum, Map<String, dynamic> data) async {
    lastOrderNum = orderNum;
    lastUpdate = data;
    if (error != null) throw _err;
    return _q;
  }

  @override
  Future<void> deleteQuestion(int orderNum) async {
    lastOrderNum = orderNum;
    if (error != null) throw _err;
  }

  @override
  Future<List<QuestionModel>> reorderQuestions(Map<String, dynamic> data) async {
    lastReorder = data;
    if (error != null) throw _err;
    return questions ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeQuestionService.${invocation.memberName}');
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

QuestionRepository _repo(QuestionService s) =>
    QuestionRepository(s, NetworkManager.instance);

void main() {
  group('createQuestion — map oldugu gibi gecer', () {
    test('time_limit dahil tum alanlar degistirilmeden iletilir', () async {
      // `time_limit` artik sunucuda economy config'ten dogrulaniyor; istemci
      // sabit bir listeye gore kirpma yapmamali (2026-09-09 duzeltmesi).
      final fake = _FakeQuestionService();
      final data = {
        'order_num': 1,
        'question_text': 'Favori rengim?',
        'correct_answer': 1,
        'answer_1': 'Mavi', 'answer_2': 'Yesil', 'answer_3': 'Kirmizi', 'answer_4': 'Sari',
        'time_limit': 20,
        'locale': 'tr',
      };

      await _repo(fake).createQuestion(data);

      expect(fake.lastCreate, data);
      expect(fake.lastCreate!['time_limit'], 20);
    });

    test('soru tavani dolunca ServerFailure kodu tasinir', () async {
      final fake = _FakeQuestionService(
        error: _dio(DioExceptionType.badResponse,
            status: 403, body: {'error': {'code': 'MAX_QUESTIONS_REACHED'}}),
      );

      final result = await _repo(fake).createQuestion(const {});

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'MAX_QUESTIONS_REACHED');
    });

    test('config disi time_limit sunucudan VALIDATION_ERROR olarak doner', () async {
      // Kontrol artik serviste (question.service.assertTimeLimitAllowed);
      // istemci yalnizca hatayi tasiyor.
      final fake = _FakeQuestionService(
        error: _dio(DioExceptionType.badResponse,
            status: 400, body: {'error': {'code': 'VALIDATION_ERROR'}}),
      );

      final result = await _repo(fake).createQuestion(const {'time_limit': 7});

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'VALIDATION_ERROR');
    });

    test('hata durumunda servis TAM BIR KEZ cagrilir — mukerrer soru olusmasin', () async {
      final fake = _FakeQuestionService(error: _dio(DioExceptionType.receiveTimeout));

      await _repo(fake).createQuestion(const {'question_text': 'x'});

      expect(fake.createCallCount, 1);
    });
  });

  group('updateQuestion / deleteQuestion', () {
    test('sira numarasi ve map ayri ayri iletilir', () async {
      final fake = _FakeQuestionService();

      await _repo(fake).updateQuestion(3, const {'time_limit': 45});

      expect(fake.lastOrderNum, 3);
      expect(fake.lastUpdate, {'time_limit': 45});
    });

    test('deleteQuestion sira numarasini gonderir', () async {
      final fake = _FakeQuestionService();

      final result = await _repo(fake).deleteQuestion(2);

      expect(fake.lastOrderNum, 2);
      expect(result.isSuccess, isTrue);
    });
  });

  group('reorderQuestions', () {
    test('payload {order: [...]} seklinde gonderilir', () async {
      // Sunucu semasi `order: z.array(uuid).min(1).max(20)`.
      final fake = _FakeQuestionService();

      await _repo(fake).reorderQuestions(const ['id-1', 'id-2', 'id-3']);

      expect(fake.lastReorder, {'order': ['id-1', 'id-2', 'id-3']});
    });

    test('sira listesi kirpilmadan gecer', () async {
      // Tavan 20; istemci 10'da kesmemeli (eski validator sabiti 10'du).
      final fake = _FakeQuestionService();
      final ids = List.generate(12, (i) => 'id-$i');

      await _repo(fake).reorderQuestions(ids);

      expect((fake.lastReorder!['order'] as List).length, 12);
    });
  });

  group('getMyQuestions', () {
    test('bos liste basarili yanittir — soru yazmamis kullanici hata gormesin', () async {
      final result = await _repo(_FakeQuestionService()).getMyQuestions();

      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d, failure: (_) => null), isEmpty);
    });

    test('dolu liste modele gecer — sira numaralari korunur', () async {
      // Sira numarasi profil gorunurlugunde onemli: kullanici sorulari bu
      // sirayla cozuyor.
      final fake = _FakeQuestionService(questions: const [
        QuestionModel(
          id: 'q1', userId: 'u1', orderNum: 1, questionText: 'Bir?',
          correctAnswer: 1, answer1: 'A', answer2: 'B', answer3: 'C', answer4: 'D',
        ),
        QuestionModel(
          id: 'q2', userId: 'u1', orderNum: 2, questionText: 'Iki?',
          correctAnswer: 2, answer1: 'A', answer2: 'B', answer3: 'C', answer4: 'D',
        ),
      ]);

      final result = await _repo(fake).getMyQuestions();

      final list = result.when(success: (d) => d, failure: (_) => null)!;
      expect(list.map((q) => q.orderNum), [1, 2]);
    });

    test('ag hatasi Failure olur', () async {
      final fake = _FakeQuestionService(error: _dio(DioExceptionType.connectionError));

      final result = await _repo(fake).getMyQuestions();

      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });
  });
}
