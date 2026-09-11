import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

/// Discover kuyrugu — yukleme, prefetch, reddet/begen, geri al.
///
/// Geri alma ucretli (Plus gunde 3, Premium sinirsiz); buton
/// `discover_card_view` → `canUndo` (= `lastSwipedCard != null`) ile acilir.
/// Bos-sebep akisi ayrica `discover_empty_reason_flow_test`'te.
void main() {
  group('yukleme ve prefetch', () {
    test('kartlar yuklenir; 3\'ten fazla kart varken prefetch yapilmaz', () async {
      final h = await _Harness.create([_page(['a', 'b', 'c', 'd', 'e'])]);

      await h.notifier.loadCards();
      await _settle();

      expect(h.ids, ['a', 'b', 'c', 'd', 'e']);
      expect(h.state.initialized, isTrue);
      expect(h.state.hasMore, isTrue);
      expect(h.repo.discoverCalls, 1);
    });

    test('ilk batch kucukse prefetch hemen baslar', () async {
      final h = await _Harness.create([_page(['a', 'b']), _page(['c'])]);

      await h.notifier.loadCards();
      await _settle();

      expect(h.repo.discoverCalls, 2);
      expect(h.ids, ['a', 'b', 'c']);
    });

    test('yukleme hatasi AsyncError', () async {
      final h = await _Harness.create([const Failure<DiscoverResponse>(NetworkFailure())]);

      await h.notifier.loadCards();

      expect(h.container.read(discoverProvider).hasError, isTrue);
    });

    test('prefetch daha once gosterilen profili tekrar eklemez', () async {
      // Sunucu henuz islemedigi swipe'i tekrar dondurebilir.
      final h = await _Harness.create([_page(['a', 'b']), _page(['b', 'c'])]);

      await h.notifier.loadCards();
      await _settle();

      expect(h.ids, ['a', 'b', 'c']);
    });

    test('prefetch yeni kart getirmezse durur (sonsuz prefetch yok)', () async {
      final h = await _Harness.create([_page(['a']), _page(['a'])]);

      await h.notifier.loadCards();
      await _settle();

      expect(h.state.hasMore, isFalse);
      expect(h.state.isPrefetching, isFalse);
    });

    test('prefetch hatasi hasMore\'u kapatir — her rebuild\'de tekrar istek atilmaz', () async {
      final h = await _Harness.create([_page(['a']), const Failure<DiscoverResponse>(NetworkFailure())]);

      await h.notifier.loadCards();
      await _settle();

      expect(h.state.hasMore, isFalse);
      expect(h.state.isPrefetching, isFalse);
      expect(h.ids, ['a']);
    });
  });

  group('reddet / begen', () {
    test('reddet: kart aninda cikar, REJECT gider, geri alinabilir', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e']);

      h.notifier.rejectCard('b');

      expect(h.ids, ['a', 'c', 'd', 'e']);
      expect(h.repo.swipes, ['REJECT:b']);
      expect(h.state.canUndo, isTrue);
    });

    test('kuyrukta olmayan kart reddedilmez, sunucuya gidilmez', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e']);

      h.notifier.rejectCard('x');

      expect(h.ids, hasLength(5));
      expect(h.repo.swipes, isEmpty);
    });

    test('begen: basarida kart cikar ve eslesme sonucu doner', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e'])
        ..repo.swipeResult = const Success(SwipeResponse(matched: true));

      final result = await h.notifier.swipe(targetId: 'a', action: 'LIKE');

      expect(result.when(success: (r) => r.matched, failure: (_) => null), isTrue);
      expect(h.ids, ['b', 'c', 'd', 'e']);
    });

    test('begen hatasinda kart kuyrukta kalir', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e'])
        ..repo.swipeResult = const Failure(ServerFailure(code: 'SWIPE_LIMIT_REACHED', statusCode: 429));

      await h.notifier.swipe(targetId: 'a', action: 'LIKE');

      expect(h.ids.first, 'a');
    });
  });

  group('geri al', () {
    test('son swipe yoksa sunucuya gidilmez', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e']);

      final result = await h.notifier.undoSwipe();

      expect(result.isFailure, isTrue);
      expect(h.repo.undoneTarget, isNull);
    });

    test('basarida kart basa doner ve geri alma hakki kapanir', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e']);
      h.notifier.rejectCard('a');

      await h.notifier.undoSwipe();

      expect(h.repo.undoneTarget, 'a');
      expect(h.ids, ['a', 'b', 'c', 'd', 'e']);
      expect(h.state.canUndo, isFalse);
    });

    test('hak bitince (UNDO_LIMIT_REACHED) kuyruk degismez', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e']);
      h.notifier.rejectCard('a');
      h.repo.undoResult = const Failure(ServerFailure(code: 'UNDO_LIMIT_REACHED', statusCode: 403));

      await h.notifier.undoSwipe();

      expect(h.ids, ['b', 'c', 'd', 'e']);
    });

    test('kuyrukta <=3 kart ve havuz acikken reddedilen kart GERI ALINABILIR', () async {
      // Eskiden reddet → prefetch baslar → `copyWith(isPrefetching: true)`
      // lastSwipedCard'i siliyordu; prefetch bitince de silinmis kaliyordu.
      final gate = Completer<Result<DiscoverResponse>>();
      final h = await _Harness.create([_page(['a', 'b', 'c', 'd']), gate]);
      await h.notifier.loadCards();

      h.notifier.rejectCard('a');
      expect(h.state.isPrefetching, isTrue, reason: 'senaryo: prefetch tetiklendi');
      expect(h.state.canUndo, isTrue);

      gate.complete(_page(['e']));
      await _settle();
      expect(h.state.canUndo, isTrue, reason: 'prefetch bitmesi geri alma hakkini silmemeli');
    });

    test('geri alma beklerken biten prefetch\'in kartlari kaybolmaz', () async {
      // `undoSwipe` await oncesi anlik goruntuyu yaziyordu: prefetch'in
      // ekledigi kartlar dusuyor (ve "gosterildi" sayildiklari icin oturumda
      // bir daha gelmiyorlardi), isPrefetching de true'da takili kaliyordu.
      final prefetchGate = Completer<Result<DiscoverResponse>>();
      final h = await _Harness.create([_page(['a', 'b', 'c', 'd']), prefetchGate]);
      await h.notifier.loadCards();
      h.notifier.rejectCard('a');
      final undoGate = Completer<Result<ProfileCardModel>>();
      h.repo.undoGate = undoGate;

      final undo = h.notifier.undoSwipe();
      prefetchGate.complete(_page(['e', 'f']));
      await _settle();
      undoGate.complete(Success(_card('a')));
      await undo;

      expect(h.ids, ['a', 'b', 'c', 'd', 'e', 'f']);
      expect(h.state.isPrefetching, isFalse);
    });
  });
}

ProfileCardModel _card(String id) =>
    ProfileCardModel(userId: id, questionCount: 2, distanceKm: 10, distanceTier: 0);

Result<DiscoverResponse> _page(List<String> ids) =>
    Success(DiscoverResponse(cards: [for (final id in ids) _card(id)], page: 1, hasMore: true));

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness._(this.repo) {
    container = ProviderContainer(overrides: [matchRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
  }

  static Future<_Harness> create(List<Object> discoverScript) async {
    final h = _Harness._(_FakeMatchRepository(discoverScript));
    await h.container.read(discoverProvider.future);
    return h;
  }

  /// 3'ten fazla kartla yuklenmis, prefetch'siz baslangic.
  static Future<_Harness> loaded(List<String> ids) async {
    final h = await create([_page(ids)]);
    await h.notifier.loadCards();
    await _settle();
    return h;
  }

  final _FakeMatchRepository repo;
  late final ProviderContainer container;

  DiscoverNotifier get notifier => container.read(discoverProvider.notifier);
  DiscoverState get state => container.read(discoverProvider).requireValue;
  List<String> get ids => state.cards.map((c) => c.userId).toList();
}

/// `discover` sirayla senaryoyu oynatir: her oge ya `Result` ya da
/// sonradan tamamlanacak `Completer<Result>` (yaris senaryolari icin).
class _FakeMatchRepository implements MatchRepository {
  _FakeMatchRepository(this._script);

  final List<Object> _script;
  int discoverCalls = 0;

  final swipes = <String>[];
  Result<SwipeResponse> swipeResult = const Success(SwipeResponse(matched: false));

  Result<ProfileCardModel>? undoResult;
  Completer<Result<ProfileCardModel>>? undoGate;
  String? undoneTarget;

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    final step = _script[discoverCalls.clamp(0, _script.length - 1)];
    discoverCalls++;
    if (step is Completer<Result<DiscoverResponse>>) return step.future;
    return step as Result<DiscoverResponse>;
  }

  @override
  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async {
    swipes.add('$action:$targetId');
    return swipeResult;
  }

  @override
  Future<Result<ProfileCardModel>> undoSwipe(String targetId) async {
    undoneTarget = targetId;
    if (undoGate != null) return undoGate!.future;
    return undoResult ?? Success(_card(targetId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeMatchRepository.${invocation.memberName}');
}
