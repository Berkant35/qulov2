import 'dart:io';
import 'dart:typed_data';

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

  FormData? lastFormData;
  String? lastUploadKind;
  String? lastDeleteKind;
  int uploadCallCount = 0;

  @override
  Future<QuestionModel> uploadVoice(int orderNum, FormData data) async {
    uploadCallCount++;
    lastOrderNum = orderNum;
    lastFormData = data;
    lastUploadKind = 'voice';
    if (error != null) throw _err;
    return _q;
  }

  @override
  Future<QuestionModel> uploadImage(int orderNum, FormData data) async {
    uploadCallCount++;
    lastOrderNum = orderNum;
    lastFormData = data;
    lastUploadKind = 'image';
    if (error != null) throw _err;
    return _q;
  }

  @override
  Future<void> deleteMedia(int orderNum, String kind) async {
    lastOrderNum = orderNum;
    lastDeleteKind = kind;
    if (error != null) throw _err;
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

  group('uploadVoice — multipart file + duration_ms', () {
    late Directory dir;
    late File file;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('qulo_voice_test');
      file = File('${dir.path}/voice.m4a')..writeAsBytesSync([1, 2, 3, 4]);
    });

    tearDown(() => dir.delete(recursive: true));

    test('file alani audio/mp4 ve duration_ms alani siraya gonderilir', () async {
      final fake = _FakeQuestionService();

      final result = await _repo(fake).uploadVoice(2, file, 7300);

      expect(result.isSuccess, isTrue);
      expect(fake.lastUploadKind, 'voice');
      expect(fake.lastOrderNum, 2);
      final form = fake.lastFormData!;
      expect(Map.fromEntries(form.fields)['duration_ms'], '7300');
      final part = form.files.single;
      expect(part.key, 'file');
      expect(part.value.contentType.toString(), 'audio/mp4');
      expect(part.value.length, 4);
    });

    test('FEATURE_DISABLED (403) kodu tasinir', () async {
      final fake = _FakeQuestionService(
        error: _dio(DioExceptionType.badResponse,
            status: 403, body: {'error': {'code': 'FEATURE_DISABLED'}}),
      );

      final result = await _repo(fake).uploadVoice(1, file, 1000);

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'FEATURE_DISABLED');
    });

    test('QUESTION_MEDIA_CONFLICT (409) kodu tasinir, servis bir kez cagrilir', () async {
      final fake = _FakeQuestionService(
        error: _dio(DioExceptionType.badResponse,
            status: 409, body: {'error': {'code': 'QUESTION_MEDIA_CONFLICT'}}),
      );

      final result = await _repo(fake).uploadVoice(1, file, 1000);

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'QUESTION_MEDIA_CONFLICT');
      expect(fake.uploadCallCount, 1);
    });

    test('dosya okunamazsa Failure doner, servis cagrilmaz', () async {
      final fake = _FakeQuestionService();

      final result = await _repo(fake).uploadVoice(1, File('${dir.path}/yok.m4a'), 1000);

      expect(result.isFailure, isTrue);
      expect(fake.uploadCallCount, 0);
    });
  });

  group('uploadImage — multipart file', () {
    test('mime tipi ve uzanti korunur, duration_ms YOK', () async {
      final fake = _FakeQuestionService();

      final result = await _repo(fake)
          .uploadImage(3, Uint8List.fromList([9, 8, 7]), 'image/jpeg');

      expect(result.isSuccess, isTrue);
      expect(fake.lastUploadKind, 'image');
      expect(fake.lastOrderNum, 3);
      final form = fake.lastFormData!;
      expect(form.fields, isEmpty);
      final part = form.files.single;
      expect(part.key, 'file');
      expect(part.value.contentType.toString(), 'image/jpeg');
      expect(part.value.filename, 'image.jpg');
    });

    test('png/webp uzantisi mime tipinden turetilir', () async {
      final fake = _FakeQuestionService();

      await _repo(fake).uploadImage(1, Uint8List(1), 'image/png');
      expect(fake.lastFormData!.files.single.value.filename, 'image.png');

      await _repo(fake).uploadImage(1, Uint8List(1), 'image/webp');
      expect(fake.lastFormData!.files.single.value.filename, 'image.webp');
    });

    test('INVALID_FILE_TYPE (400) kodu tasinir', () async {
      final fake = _FakeQuestionService(
        error: _dio(DioExceptionType.badResponse,
            status: 400, body: {'error': {'code': 'INVALID_FILE_TYPE'}}),
      );

      final result = await _repo(fake).uploadImage(1, Uint8List(1), 'image/gif');

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'INVALID_FILE_TYPE');
    });
  });

  group('removeMedia', () {
    test('kind yol parcasi olarak gider (voice / image)', () async {
      final fake = _FakeQuestionService();

      final voice = await _repo(fake).removeMedia(2, QuestionMediaKind.voice);
      expect(fake.lastDeleteKind, 'voice');
      expect(fake.lastOrderNum, 2);
      expect(voice.isSuccess, isTrue);

      await _repo(fake).removeMedia(2, QuestionMediaKind.image);
      expect(fake.lastDeleteKind, 'image');
    });

    test('QUESTION_NOT_FOUND (404) kodu tasinir', () async {
      final fake = _FakeQuestionService(
        error: _dio(DioExceptionType.badResponse,
            status: 404, body: {'error': {'code': 'QUESTION_NOT_FOUND'}}),
      );

      final result = await _repo(fake).removeMedia(9, QuestionMediaKind.image);

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'QUESTION_NOT_FOUND');
    });
  });
}
