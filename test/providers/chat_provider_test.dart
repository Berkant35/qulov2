import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/media_request_model.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/data/repositories/chat_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';

/// Sohbet durumu — mesaj listesi, sayfalama, tepki, silme, medya, sohbet kilidi.
///
/// Sunucu sozlesmeleri (qulo-server `chat.service.ts`):
/// - `getMessages` OFFSET sayfalama (`created_at desc` + `range`) — yeni mesaj
///   sonraki sayfayi kaydirir.
/// - `addReaction` TOGGLE (`UNIQUE (message_id, user_id, emoji)`, prod'da
///   dogrulandi): ayni emoji tekrar → `{toggled: 'removed'}`.
/// Realtime handler kendi mesajini filtreliyor (`chat_realtime_mixin`).
void main() {
  group('yukleme ve gonderim', () {
    test('ilk sayfa yuklenir', () async {
      final h = await _Harness.create(page1: _page(['m2', 'm1'], total: 2));

      expect(h.ids, ['m2', 'm1']);
      expect(h.state.total, 2);
      expect(h.state.page, 1);
    });

    test('yukleme hatasi AsyncError olur', () async {
      final repo = _FakeChatRepository()
        ..pages[1] = const Failure<MessagesResponse>(ServerFailure(code: 'NOT_A_PARTICIPANT', statusCode: 403));
      final container = _container(repo);

      await expectLater(container.read(chatProvider('m1').future), throwsA(isA<ServerFailure>()));
    });

    test('gonderilen mesaj basa eklenir, toplam artar', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));

      await h.notifier.sendMessage('selam');

      expect(h.ids, ['sent', 'm1']);
      expect(h.state.total, 2);
    });

    test('gonderim hatasi listeyi degistirmez', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));
      h.repo.sendResult = const Failure(ServerFailure(code: 'CHAT_LOCKED', statusCode: 403));

      final result = await h.notifier.sendMessage('selam');

      expect(result.isFailure, isTrue);
      expect(h.ids, ['m1']);
      expect(h.state.total, 1);
    });

    test('realtime mesaj basa eklenir', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));

      h.notifier.addRealtimeMessage(_msg('m2'));

      expect(h.ids, ['m2', 'm1']);
      expect(h.state.total, 2);
    });
  });

  group('sayfalama', () {
    test('sonraki sayfa sona eklenir, sayfa numarasi artar', () async {
      final h = await _Harness.create(page1: _page(['m3', 'm2'], total: 3))
        ..repo.pages[2] = Success(_page(['m1'], total: 3, page: 2));

      expect(h.notifier.hasMore, isTrue);
      await h.notifier.loadMore();

      expect(h.ids, ['m3', 'm2', 'm1']);
      expect(h.state.page, 2);
      expect(h.notifier.hasMore, isFalse);
    });

    test('hepsi yuklendiyse sunucuya gidilmez', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));

      await h.notifier.loadMore();

      expect(h.repo.requestedPages, [1]);
    });

    test('mesaj gonderildikten sonra sinirdaki mesaj IKI KEZ eklenmez', () async {
      // Sunucuda 31 mesaj; ilk sayfa en yeni 30'u (m31..m2) getirir. Kullanici
      // mesaj gonderir → sunucuda 32 olur, offset 30 artik [m2, m1] doner.
      // Eskiden m2 listede iki kez gorunuyordu.
      final first = [for (var i = 31; i >= 2; i--) 'm$i'];
      final h = await _Harness.create(page1: _page(first, total: 31));
      await h.notifier.sendMessage('yeni');
      h.repo.pages[2] = Success(_page(['m2', 'm1'], total: 32, page: 2));

      await h.notifier.loadMore();

      expect(h.ids.where((id) => id == 'm2'), hasLength(1));
      expect(h.ids, hasLength(32));
      expect(h.ids.last, 'm1');
    });
  });

  group('tepki (sunucu toggle)', () {
    test('eklenen tepki mesajda gorunur', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));

      await h.notifier.addReaction('m1', '❤️');

      expect(h.reactionsOf('m1'), [const MessageReaction(emoji: '❤️', userId: 'me')]);
    });

    test('ayni emoji tekrar secilince kalkar — baskasinin ayni tepkisi kalir', () async {
      // Eskiden yanit yok sayilip her zaman ekleniyordu: sunucu kaldirirken
      // ekran tepkiyi iki kez gosteriyordu.
      final h = await _Harness.create(page1: MessagesResponse(
        messages: [
          _msg('m1', reactions: const [
            MessageReaction(emoji: '❤️', userId: 'me'),
            MessageReaction(emoji: '❤️', userId: 'other'),
          ]),
        ],
        total: 1,
        page: 1,
        limit: 30,
      ));
      h.repo.reactionResult = const Success({'toggled': 'removed'});

      await h.notifier.addReaction('m1', '❤️');

      expect(h.reactionsOf('m1'), [const MessageReaction(emoji: '❤️', userId: 'other')]);
    });

    test('zaten verilmis tepki eklenirse tekrarlanmaz', () async {
      final h = await _Harness.create(page1: MessagesResponse(
        messages: [_msg('m1', reactions: const [MessageReaction(emoji: '🔥', userId: 'me')])],
        total: 1,
        page: 1,
        limit: 30,
      ));

      await h.notifier.addReaction('m1', '🔥');

      expect(h.reactionsOf('m1'), [const MessageReaction(emoji: '🔥', userId: 'me')]);
    });

    test('hata listeyi degistirmez', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));
      h.repo.reactionResult = const Failure(NetworkFailure());

      await h.notifier.addReaction('m1', '❤️');

      expect(h.reactionsOf('m1'), isNull);
    });
  });

  group('silme ve medya', () {
    test('silinen mesaj isaretlenir; icerik ve tepkiler korunur, digerleri etkilenmez', () async {
      final h = await _Harness.create(page1: MessagesResponse(
        messages: [
          _msg('m2'),
          _msg('m1', reactions: const [MessageReaction(emoji: '😂', userId: 'other')]),
        ],
        total: 2,
        page: 1,
        limit: 30,
      ));

      await h.notifier.deleteMessage('m1');

      final deleted = h.state.messages.last;
      expect(deleted.isDeleted, isTrue);
      expect(deleted.content, 'mesaj m1');
      expect(deleted.reactions, hasLength(1));
      expect(h.state.messages.first.isDeleted, isFalse);
    });

    test('medya istegi kabul edilince medya acilir ve bekleyen istek temizlenir', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));
      await h.notifier.requestMedia();
      expect(h.state.pendingMediaRequest?.id, 'r1');

      await h.notifier.respondToMediaRequest('r1', 'accept');

      expect(h.state.mediaEnabled, isTrue);
      expect(h.state.pendingMediaRequest, isNull);
    });

    test('medyayi kapatma sunucuya gider ve durumu kapatir', () async {
      final h = await _Harness.create(page1: _page(['m1'], total: 1));

      await h.notifier.disableMedia();

      expect(h.repo.disableCalls, 1);
      expect(h.state.mediaEnabled, isFalse);
    });
  });

  group('sohbet kilidi', () {
    Future<bool> lockedWith(ChatQuestionModel question) async {
      final h = await _Harness.create(page1: MessagesResponse(
        messages: [_msg('q-msg', content: '__QUESTION__:${question.id}'), _msg('m1')],
        total: 2,
        page: 1,
        limit: 30,
      ));
      h.notifier.updateChatLock(currentUserId: 'me', questionCache: {question.id: question});
      return h.state.hasChatLock;
    }

    test('karsi tarafin cevaplanmamis kilitli sorusu sohbeti kilitler', () async {
      expect(await lockedWith(_question(sender: 'other', chatLock: true)), isTrue);
    });

    test('soruyu soran benim → kilit yok', () async {
      expect(await lockedWith(_question(sender: 'me', chatLock: true)), isFalse);
    });

    test('cevaplanmis soru kilitlemez', () async {
      expect(await lockedWith(_question(sender: 'other', chatLock: true, answered: 'A')), isFalse);
    });

    test('kilitsiz soru kilitlemez', () async {
      expect(await lockedWith(_question(sender: 'other', chatLock: false)), isFalse);
    });

    test('soru onbellekte yoksa kilit yok', () async {
      final h = await _Harness.create(page1: MessagesResponse(
        messages: [_msg('q-msg', content: '__QUESTION__:q9')],
        total: 1,
        page: 1,
        limit: 30,
      ));

      h.notifier.updateChatLock(currentUserId: 'me', questionCache: const {});

      expect(h.state.hasChatLock, isFalse);
    });
  });
}

MessageModel _msg(String id, {String content = '', List<MessageReaction>? reactions}) => MessageModel(
      id: id,
      matchId: 'm1',
      senderId: 'other',
      content: content.isEmpty ? 'mesaj $id' : content,
      reactions: reactions,
      createdAt: '2026-09-11T10:00:00Z',
    );

MessagesResponse _page(List<String> ids, {required int total, int page = 1}) =>
    MessagesResponse(messages: [for (final id in ids) _msg(id)], total: total, page: page, limit: 30);

ChatQuestionModel _question({required String sender, required bool chatLock, String? answered}) =>
    ChatQuestionModel(
      id: 'q1',
      matchId: 'm1',
      senderId: sender,
      questionText: 'En sevdigim sehir?',
      optionA: 'Izmir',
      optionB: 'Ankara',
      createdAt: '2026-09-11T10:00:00Z',
      hasChatLock: chatLock,
      answeredOption: answered,
    );

class _SeededAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated, userId: 'me');
}

ProviderContainer _container(_FakeChatRepository repo) {
  final container = ProviderContainer(overrides: [
    chatRepositoryProvider.overrideWithValue(repo),
    authProvider.overrideWith(_SeededAuthNotifier.new),
  ]);
  addTearDown(container.dispose);
  return container;
}

class _Harness {
  _Harness._(this.repo, this.container);

  static Future<_Harness> create({required MessagesResponse page1}) async {
    final repo = _FakeChatRepository()..pages[1] = Success(page1);
    final container = _container(repo);
    await container.read(chatProvider('m1').future);
    return _Harness._(repo, container);
  }

  final _FakeChatRepository repo;
  final ProviderContainer container;

  ChatNotifier get notifier => container.read(chatProvider('m1').notifier);
  ChatState get state => container.read(chatProvider('m1')).requireValue;
  List<String> get ids => state.messages.map((m) => m.id).toList();
  List<MessageReaction>? reactionsOf(String id) =>
      state.messages.firstWhere((m) => m.id == id).reactions;
}

class _FakeChatRepository implements ChatRepository {
  final pages = <int, Result<MessagesResponse>>{};
  final requestedPages = <int>[];

  Result<MessageModel> sendResult = Success(MessageModel(
    id: 'sent',
    matchId: 'm1',
    senderId: 'me',
    content: 'selam',
    createdAt: '2026-09-11T10:05:00Z',
  ));
  Result<Map<String, dynamic>> reactionResult = const Success({'toggled': 'added'});
  int disableCalls = 0;

  @override
  Future<Result<MessagesResponse>> getMessages(String matchId, {int page = 1, int limit = 30}) async {
    requestedPages.add(page);
    return pages[page] ?? Success(MessagesResponse(messages: const [], total: 0, page: page, limit: limit));
  }

  @override
  Future<Result<MessageModel>> sendMessage(
    String matchId, {
    required String content,
    bool isImage = false,
    String? audioUrl,
    int? audioDurationSeconds,
  }) async =>
      sendResult;

  @override
  Future<Result<Map<String, dynamic>>> addReaction(String matchId, String messageId, String emoji) async =>
      reactionResult;

  @override
  Future<Result<void>> deleteMessage(String matchId, String messageId) async => const Success(null);

  @override
  Future<Result<MediaRequestModel>> requestMedia(String matchId) async =>
      Success(MediaRequestModel(id: 'r1', status: 'pending'));

  @override
  Future<Result<Map<String, dynamic>>> respondToMediaRequest(
    String matchId,
    String requestId,
    String action,
  ) async =>
      const Success({'media_enabled': true});

  @override
  Future<Result<void>> disableMedia(String matchId) async {
    disableCalls++;
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeChatRepository.${invocation.memberName}');
}
