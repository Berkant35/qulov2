import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/chat_service.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/data/repositories/chat_repository.dart';

/// Chat repository'si — 21 metot; CLAUDE.md önceliğine göre `sendMessage`,
/// `getMessages`, `usePower` ve soru/güç yolu test edildi.
///
/// EN ÖNEMLİ SÖZLEŞME — `use_power_block` vs `has_power_block`:
/// aynı kavramın iki adı var ve yönleri farklı.
///   İSTEK  → `use_power_block`  (chat-question.validator.ts:17)
///   YANIT  → `has_power_block`  (chat-question.service.ts:299 bu adla yazıyor)
/// Bu karışıklık alanın üç kez yanlış gönderilip geri alınmasına yol açtı.
/// Repository map'i **olduğu gibi** iletiyor; araya girip ad dönüştürmemeli.
///
/// Ayrıca güç enum'ları iki uçta FARKLI, bilinçli olarak:
///   kullanım (chat-question.validator.ts:39) → 6 değer, `POWER_BLOCK` YOK
///   satın alma (exchange.validator.ts:18)    → 8 değer, `POWER_BLOCK` VAR
/// Çünkü POWER_BLOCK soru oluştururken uygulanıyor, kullanım anında değil.
class _FakeChatService implements ChatService {
  _FakeChatService({this.error, this.powerResponse});

  final DioException? error;
  final Map<String, dynamic>? powerResponse;

  String? lastMatchId;
  String? lastQuestionId;
  Map<String, dynamic>? lastSendPayload;
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastPowerPayload;
  int? lastPage;
  int? lastLimit;
  int sendCallCount = 0;
  int powerCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<MessagesResponse> getMessages(String matchId, int page, int limit) async {
    lastMatchId = matchId;
    lastPage = page;
    lastLimit = limit;
    if (error != null) throw _err;
    return const MessagesResponse(messages: [], total: 0, page: 1, limit: 30);
  }

  @override
  Future<MessageModel> sendMessage(String matchId, Map<String, dynamic> data) async {
    sendCallCount++;
    lastMatchId = matchId;
    lastSendPayload = data;
    if (error != null) throw _err;
    return const MessageModel(
      id: 'msg1', matchId: 'm1', senderId: 'u1', content: 'selam',
    );
  }

  @override
  Future<ChatQuestionModel> createQuestion(String matchId, Map<String, dynamic> data) async {
    lastMatchId = matchId;
    lastCreatePayload = data;
    if (error != null) throw _err;
    return const ChatQuestionModel(
      id: 'q1', matchId: 'm1', senderId: 'u1',
      questionText: 'Soru?', optionA: 'A', optionB: 'B',
      createdAt: '2026-09-09T00:00:00.000Z',
    );
  }

  @override
  Future<dynamic> usePower(String questionId, Map<String, dynamic> data) async {
    powerCallCount++;
    lastQuestionId = questionId;
    lastPowerPayload = data;
    if (error != null) throw _err;
    return powerResponse ?? <String, dynamic>{'power_name': 'ORACLE', 'cost': 5};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeChatService.${invocation.memberName}');
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

/// `ChatRepository` iki bagimlilik aliyor; `NetworkManager` yalnizca medya
/// yukleme yollarinda kullaniliyor ve burada test edilen metotlarin hicbiri
/// ona dokunmuyor, o yuzden singleton veriliyor (ag cagrisi olmuyor).
ChatRepository _repo(ChatService service) =>
    ChatRepository(service, NetworkManager.instance);

void main() {
  group('getMessages', () {
    test('varsayilan sayfalama 1/30 gonderilir', () async {
      final fake = _FakeChatService();

      await _repo(fake).getMessages('m1');

      expect(fake.lastMatchId, 'm1');
      expect(fake.lastPage, 1);
      expect(fake.lastLimit, 30);
    });

    test('verilen sayfalama oldugu gibi gecer', () async {
      final fake = _FakeChatService();

      await _repo(fake).getMessages('m1', page: 3, limit: 50);

      expect(fake.lastPage, 3);
      expect(fake.lastLimit, 50);
    });

    test('bos sohbet basarili yanittir, hata degil', () async {
      final result = await _repo(_FakeChatService()).getMessages('m1');

      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d.messages, failure: (_) => null), isEmpty);
    });
  });

  group('sendMessage — payload sozlesmesi', () {
    test('metin mesajinda yalnizca content ve is_image gider', () async {
      // Ses alanlari opsiyonel; null gonderilirse sunucu bunu "sesli mesaj ama
      // url yok" diye yorumlayabilir. Anahtarin hic olmamasi anlamli.
      final fake = _FakeChatService();

      await _repo(fake).sendMessage('m1', content: 'selam');

      expect(fake.lastSendPayload, {'content': 'selam', 'is_image': false});
    });

    test('gorsel mesajinda is_image true gider', () async {
      final fake = _FakeChatService();

      await _repo(fake).sendMessage('m1', content: 'https://x/y.jpg', isImage: true);

      expect(fake.lastSendPayload!['is_image'], true);
    });

    test('sesli mesajda url ve sure eklenir', () async {
      final fake = _FakeChatService();

      await _repo(fake).sendMessage(
        'm1', content: '', audioUrl: 'https://x/a.m4a', audioDurationSeconds: 12,
      );

      expect(fake.lastSendPayload!['audio_url'], 'https://x/a.m4a');
      expect(fake.lastSendPayload!['audio_duration_seconds'], 12);
    });

    test('ses alanlari verilmezse anahtarlar HIC gonderilmez', () async {
      final fake = _FakeChatService();

      await _repo(fake).sendMessage('m1', content: 'selam');

      expect(fake.lastSendPayload!.containsKey('audio_url'), isFalse);
      expect(fake.lastSendPayload!.containsKey('audio_duration_seconds'), isFalse);
    });

    test('hata durumunda servis TAM BIR KEZ cagrilir — mesaj iki kez gitmesin', () async {
      final fake = _FakeChatService(error: _dio(DioExceptionType.receiveTimeout));

      final result = await _repo(fake).sendMessage('m1', content: 'selam');

      expect(result.when(success: (_) => null, failure: (f) => f), isA<TimeoutFailure>());
      expect(fake.sendCallCount, 1);
    });
  });

  group('createQuestion — use_power_block map olarak gecer', () {
    test('verilen map OLDUGU GIBI iletilir, ad donusturulmez', () async {
      // Bu alan uc kez yanlis adla gonderilip geri alindi. Istek adi
      // `use_power_block` (chat-question.validator.ts:17); yanitta `has_power_block`
      // olmasi farkli bir sey (servis o adla YAZIYOR, chat-question.service.ts:299).
      // Repository araya girip donusturmemeli.
      final fake = _FakeChatService();
      final data = {
        'question_text': 'Soru?',
        'option_a': 'A',
        'option_b': 'B',
        'use_power_block': true,
      };

      await _repo(fake).createQuestion('m1', data);

      expect(fake.lastCreatePayload, data);
      expect(fake.lastCreatePayload!['use_power_block'], true);
      expect(fake.lastCreatePayload!.containsKey('has_power_block'), isFalse);
    });

    test('yetersiz bakiye ServerFailure olarak tasinir', () async {
      final fake = _FakeChatService(
        error: _dio(DioExceptionType.badResponse,
            status: 402, body: {'error': {'code': 'INSUFFICIENT_DIAMONDS'}}),
      );

      final result = await _repo(fake).createQuestion('m1', const {});

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'INSUFFICIENT_DIAMONDS');
    });
  });

  group('usePower — para yolu', () {
    test('power_name payload olarak gider', () async {
      final fake = _FakeChatService();

      await _repo(fake).usePower('q1', 'ORACLE');

      expect(fake.lastQuestionId, 'q1');
      expect(fake.lastPowerPayload, {'power_name': 'ORACLE'});
    });

    test('kullanim enumundaki her guc gonderilebilir', () async {
      // chat-question.validator.ts:39 — POWER_BLOCK burada YOK (o soru
      // olusturulurken uygulaniyor), POWER_UNBLOCK VAR.
      for (final power in ['ORACLE', 'HALF', 'HINT', 'TIME_EXTEND', 'SKIP', 'POWER_UNBLOCK']) {
        final fake = _FakeChatService();

        await _repo(fake).usePower('q1', power);

        expect(fake.lastPowerPayload!['power_name'], power);
      }
    });

    test('yanit modele parse edilir (maliyet dahil)', () async {
      final fake = _FakeChatService(powerResponse: const {
        'power_name': 'HALF', 'eliminated_options': ['B', 'C'], 'cost': 8,
      });

      final result = await _repo(fake).usePower('q1', 'HALF');

      final data = result.when(success: (d) => d, failure: (_) => null)!;
      expect(data.powerName, 'HALF');
      expect(data.cost, 8);
      expect(data.eliminatedOptions, ['B', 'C']);
    });

    test('guc zaten kullanildiysa ServerFailure ve servis bir kez cagrilir', () async {
      // Sessiz tekrar cift elmas harcamasi demek.
      final fake = _FakeChatService(
        error: _dio(DioExceptionType.badResponse,
            status: 409, body: {'error': {'code': 'POWER_ALREADY_USED'}}),
      );

      final result = await _repo(fake).usePower('q1', 'ORACLE');

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'POWER_ALREADY_USED');
      expect(fake.powerCallCount, 1);
    });
  });
}
