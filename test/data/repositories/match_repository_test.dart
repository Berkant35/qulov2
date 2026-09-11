import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/match_service.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';

/// Eşleşme repository'si — keşif, swipe, eşleşme listesi.
///
/// Sunucu sözleşmesi (`match.validator.ts`):
///   swipe    → `target_id` (uuid) + `action` ∈ {LIKE, REJECT}
///   discover → `page` (coerce int, min 1, default 1)
///
/// `emptyReason` alanı boş discover kurtarma işiyle geldi: liste boşken
/// kullanıcıya **neden** boş olduğu söylenebilsin diye. `null` olabilir ve
/// olmaması bir hata değil — bu yüzden modelde `required` değil.
class _FakeMatchService implements MatchService {
  _FakeMatchService({this.response, this.matches, this.error, this.matched = false});

  final DiscoverResponse? response;
  final List<MatchModel>? matches;
  final DioException? error;
  final bool matched;

  Map<String, dynamic>? lastSwipePayload;
  int? lastPage;
  String? lastUndoTargetId;
  String? lastUnmatchId;
  int swipeCallCount = 0;

  DioException get _err =>
      error ?? DioException(requestOptions: RequestOptions(path: '/x'));

  @override
  Future<DiscoverResponse> discover(int page) async {
    lastPage = page;
    if (error != null) throw _err;
    return response ?? const DiscoverResponse(cards: [], page: 1, hasMore: false);
  }

  @override
  Future<SwipeResponse> swipe(Map<String, dynamic> data) async {
    swipeCallCount++;
    lastSwipePayload = data;
    if (error != null) throw _err;
    return SwipeResponse(matched: matched);
  }

  @override
  Future<List<MatchModel>> getMatches() async {
    if (error != null) throw _err;
    return matches ?? const [];
  }

  @override
  Future<ProfileCardModel> undoSwipe(String targetId) async {
    lastUndoTargetId = targetId;
    if (error != null) throw _err;
    return const ProfileCardModel(userId: 'u2', name: 'Ada', questionCount: 3);
  }

  @override
  Future<void> unmatch(String matchId) async {
    lastUnmatchId = matchId;
    if (error != null) throw _err;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeMatchService.${invocation.memberName}');
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
  group('discover', () {
    test('varsayilan sayfa 1 gonderilir', () async {
      final fake = _FakeMatchService();

      await MatchRepository(fake).discover();

      expect(fake.lastPage, 1);
    });

    test('verilen sayfa oldugu gibi gecer', () async {
      final fake = _FakeMatchService();

      await MatchRepository(fake).discover(page: 4);

      expect(fake.lastPage, 4);
    });

    test('bos liste HATA DEGIL — basarili yanit olarak doner', () async {
      // Bos discover kullanicinin gercek durumu (erkeklerin %41'i goruyordu).
      // Failure'a cevrilirse ekran hata gosterir ve `emptyReason` ile
      // aciklama yapma imkani kaybolur.
      final fake = _FakeMatchService(
        response: const DiscoverResponse(cards: [], page: 1, hasMore: false),
      );

      final result = await MatchRepository(fake).discover();

      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d.cards, failure: (_) => null), isEmpty);
    });

    test('emptyReason tasinir — bosken NEDEN bos oldugu soylenebilsin', () async {
      final fake = _FakeMatchService(
        response: const DiscoverResponse(
          cards: [], page: 1, hasMore: false, emptyReason: 'no_questions',
        ),
      );

      final result = await MatchRepository(fake).discover();

      expect(result.when(success: (d) => d.emptyReason, failure: (_) => null), 'no_questions');
    });

    test('emptyReason yoksa null kalir — uydurma sebep gosterilmesin', () async {
      final fake = _FakeMatchService(
        response: const DiscoverResponse(cards: [], page: 1, hasMore: false),
      );

      final result = await MatchRepository(fake).discover();

      expect(result.when(success: (d) => d.emptyReason, failure: (_) => 'x'), isNull);
    });

    test('ag hatasi Failure olur', () async {
      final fake = _FakeMatchService(error: _dio(DioExceptionType.connectionError));

      final result = await MatchRepository(fake).discover();

      expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
    });
  });

  group('swipe — sunucu enum sozlesmesi', () {
    test('LIKE payload olarak gonderilir', () async {
      final fake = _FakeMatchService();

      await MatchRepository(fake).swipe(targetId: 'u2', action: 'LIKE');

      expect(fake.lastSwipePayload, {'target_id': 'u2', 'action': 'LIKE'});
    });

    test('REJECT payload olarak gonderilir', () async {
      // Iki deger de kullanimda: LIKE discover_card_view.dart:257,
      // REJECT match_provider.dart:130 (bilincli fire-and-forget).
      final fake = _FakeMatchService();

      await MatchRepository(fake).swipe(targetId: 'u2', action: 'REJECT');

      expect(fake.lastSwipePayload!['action'], 'REJECT');
    });

    test('eslesme sonucu tasinir — kutlama ekrani buna bakiyor', () async {
      final fake = _FakeMatchService(matched: true);

      final result = await MatchRepository(fake).swipe(targetId: 'u2', action: 'LIKE');

      expect(result.when(success: (d) => d.matched, failure: (_) => null), isTrue);
    });

    test('hata durumunda servis TAM BIR KEZ cagrilir — cift swipe olmasin', () async {
      // Sessiz tekrar, ayni adaya iki swipe kaydi demek; undo sayaci ve
      // eslesme mantigi bundan etkilenir.
      final fake = _FakeMatchService(
        error: _dio(DioExceptionType.badResponse,
            status: 409, body: {'error': {'code': 'ALREADY_SWIPED'}}),
      );

      final result = await MatchRepository(fake).swipe(targetId: 'u2', action: 'LIKE');

      expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
          'ALREADY_SWIPED');
      expect(fake.swipeCallCount, 1);
    });
  });

  group('getMatches / undoSwipe / unmatch', () {
    test('bos eslesme listesi basarili yanittir', () async {
      final result = await MatchRepository(_FakeMatchService()).getMatches();

      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d, failure: (_) => null), isEmpty);
    });

    test('eslesme listesi modele gecer', () async {
      final fake = _FakeMatchService(matches: const [
        MatchModel(matchId: 'm1', matchedAt: '2026-09-09T00:00:00.000Z', unreadCount: 3),
      ]);

      final result = await MatchRepository(fake).getMatches();

      final list = result.when(success: (d) => d, failure: (_) => null)!;
      expect(list.single.matchId, 'm1');
      expect(list.single.unreadCount, 3);
    });

    test('undoSwipe hedef kimligini gonderir ve karti geri getirir', () async {
      final fake = _FakeMatchService();

      final result = await MatchRepository(fake).undoSwipe('u2');

      expect(fake.lastUndoTargetId, 'u2');
      expect(result.when(success: (d) => d.userId, failure: (_) => null), 'u2');
    });

    test('undo hakki bittiginde kod ve params tasinir — mesaj eslemesi buna bakar', () async {
      // Sunucu: subscription.service.ts incrementDailyUndos →
      // Errors.DAILY_LIMIT_EXCEEDED('undo'). UNDO_LIMIT_REACHED diye bir kod yok.
      final fake = _FakeMatchService(
        error: _dio(DioExceptionType.badResponse, status: 403, body: {
          'error': {
            'code': 'DAILY_LIMIT_EXCEEDED',
            'params': {'resource': 'undo'},
          },
        }),
      );

      final result = await MatchRepository(fake).undoSwipe('u2');

      final failure = result.when(success: (_) => null, failure: (f) => f) as ServerFailure;
      expect(failure.code, 'DAILY_LIMIT_EXCEEDED');
      expect(failure.params, {'resource': 'undo'});
    });

    test('unmatch id gonderir ve Success(null) doner', () async {
      final fake = _FakeMatchService();

      final result = await MatchRepository(fake).unmatch('m1');

      expect(fake.lastUnmatchId, 'm1');
      expect(result.isSuccess, isTrue);
    });
  });
}
