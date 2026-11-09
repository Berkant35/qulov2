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

    test('begen NOT_COMPATIBLE: uyumsuz kart desteden duser, geri alinamaz', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e'])
        ..repo.swipeResult = const Failure(ServerFailure(code: 'NOT_COMPATIBLE', statusCode: 403));

      final result = await h.notifier.swipe(targetId: 'b', action: 'LIKE');

      expect(result.when(success: (_) => null, failure: isNotCompatibleFailure), isTrue);
      expect(h.ids, ['a', 'c', 'd', 'e']);
      expect(h.state.canUndo, isFalse);
    });

    test('begen USER_NOT_FOUND (404): NOT_COMPATIBLE gibi kart desteden duser', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e'])
        ..repo.swipeResult = const Failure(ServerFailure(code: 'USER_NOT_FOUND', statusCode: 404));

      final result = await h.notifier.swipe(targetId: 'b', action: 'LIKE');

      expect(result.when(success: (_) => null, failure: isNotCompatibleFailure), isTrue);
      expect(h.ids, ['a', 'c', 'd', 'e']);
      expect(h.state.canUndo, isFalse);
    });

    test('begen baska bir 403 hatasinda kart kuyrukta kalir', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e'])
        ..repo.swipeResult = const Failure(ServerFailure(code: 'FORBIDDEN', statusCode: 403));

      await h.notifier.swipe(targetId: 'b', action: 'LIKE');

      expect(h.ids, ['a', 'b', 'c', 'd', 'e']);
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

    test('hak bitince (sunucu DAILY_LIMIT_EXCEEDED, resource undo) kuyruk degismez', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e']);
      h.notifier.rejectCard('a');
      h.repo.undoResult = const Failure(ServerFailure(
        code: 'DAILY_LIMIT_EXCEEDED',
        statusCode: 403,
        params: {'resource': 'undo'},
      ));

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

    test('geri alinan red sonrasi "Yeniden Ara" karti tekrar gosterebilir', () async {
      // Geri alma swipe'i sunucuda siler: kart artik reddedilmis sayilmaz.
      final h = await _Harness.create([_page(['a', 'b', 'c', 'd', 'e'])]);
      await h.notifier.loadCards();
      h.notifier.rejectCard('a');
      await _settle();
      await h.notifier.undoSwipe();

      await h.notifier.loadCards();
      await _settle();

      expect(h.ids, ['a', 'b', 'c', 'd', 'e']);
    });
  });

  group('reddin teslimi — yaris ve gunluk hak', () {
    test('"Yeniden Ara": REJECT\'i yolda olan kart geri gelmez', () async {
      // Prod: REJECT insert'inden saniyeler once ayni hedef yeniden servis edildi.
      final inFlight = Completer<Result<SwipeResponse>>();
      final h = await _Harness.create([
        _page(['a', 'b', 'c', 'd', 'e']),
        _page(['b', 'f', 'g', 'h', 'i']),
      ]);
      await h.notifier.loadCards();
      h.repo.swipeScript.add(inFlight);
      h.notifier.rejectCard('b');

      await h.notifier.loadCards();
      await _settle();
      expect(h.ids, ['f', 'g', 'h', 'i']);

      inFlight.complete(const Success(SwipeResponse(matched: false)));
      await _settle();
      expect(h.ids, ['f', 'g', 'h', 'i']);
    });

    test('suzme sonrasi deste bossa prefetch bir kez dener ve durur (dongu yok)', () async {
      final h = await _Harness.create([
        _page(['a', 'b', 'c', 'd', 'e']),
        _page(['a']),
      ]);
      await h.notifier.loadCards();
      h.repo.swipeScript.add(Completer<Result<SwipeResponse>>());
      h.notifier.rejectCard('a');

      await h.notifier.loadCards();
      await _settle();
      // Ekran bos+hasMore'da her karede maybePrefetch cagirir.
      await h.notifier.maybePrefetch();
      await _settle();

      expect(h.ids, isEmpty);
      expect(h.state.hasMore, isFalse);
      expect(h.state.isPrefetching, isFalse);
      expect(h.repo.discoverCalls, 3, reason: 'ilk + yeniden ara + tek prefetch');
    });

    test('gunluk hak 403: kart destenin basina doner, sinyal artar, geri alma kapanir', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e']);
      h.repo.swipeResult = _dailyLimit;

      h.notifier.rejectCard('b');
      expect(h.ids, ['a', 'c', 'd', 'e'], reason: 'iyimser cikis');
      await _settle();

      expect(h.ids, ['b', 'a', 'c', 'd', 'e']);
      expect(h.state.swipeLimitHits, 1);
      expect(h.state.canUndo, isFalse, reason: 'kaydi olmayan red geri alinamaz');
      expect(h.repo.swipes, ['REJECT:b'], reason: 'hak hatasi yeniden denenmez');
    });

    test('gunluk hak 403: sonra reddedilen kartin geri alma hakki korunur', () async {
      final h = await _Harness.loaded(['a', 'b', 'c', 'd', 'e', 'f']);
      final inFlight = Completer<Result<SwipeResponse>>();
      h.repo.swipeScript.add(inFlight);

      h.notifier.rejectCard('b');
      // b'nin yaniti gelmeden kullanici c'yi de reddetti (o kaydedildi).
      h.notifier.rejectCard('c');
      await _settle();
      inFlight.complete(_dailyLimit);
      await _settle();

      expect(h.ids, ['b', 'a', 'd', 'e', 'f']);
      expect(h.state.swipeLimitHits, 1);
      expect(h.state.lastSwipedCard?.userId, 'c');
    });

    test('gunluk hak 403 sonrasi "Yeniden Ara" karti gosterir (red kaydi yok)', () async {
      final h = await _Harness.create([
        _page(['a', 'b', 'c', 'd', 'e']),
        _page(['a', 'f', 'g', 'h']),
      ]);
      await h.notifier.loadCards();
      h.repo.swipeResult = _dailyLimit;
      h.notifier.rejectCard('a');
      await _settle();

      await h.notifier.loadCards();
      await _settle();

      expect(h.ids, ['a', 'f', 'g', 'h']);
      expect(h.state.swipeLimitHits, 1, reason: 'yeniden yukleme sinyali sifirlamaz');
    });

    testWidgets('ag hatasinda ~2 sn sonra tek yeniden deneme; yine olmazsa kart oturumda gelmez',
        (tester) async {
      Future<void> settle() async {
        for (var i = 0; i < 5; i++) {
          await tester.pump();
        }
      }

      final h = await _Harness.create([
        _page(['a', 'b', 'c', 'd', 'e']),
        _page(['a', 'f', 'g', 'h']),
      ]);
      await h.notifier.loadCards();
      h.repo.swipeScript.addAll([
        const Failure<SwipeResponse>(NetworkFailure()),
        const Failure<SwipeResponse>(ServerFailure(code: 'INTERNAL', statusCode: 500)),
      ]);

      h.notifier.rejectCard('a');
      await settle();
      expect(h.repo.swipes, ['REJECT:a']);

      await tester.pump(const Duration(milliseconds: 1900));
      expect(h.repo.swipes, ['REJECT:a'], reason: 'beklemeden denemez');
      await tester.pump(const Duration(milliseconds: 200));
      await settle();
      expect(h.repo.swipes, ['REJECT:a', 'REJECT:a']);

      await tester.pump(const Duration(seconds: 10));
      expect(h.repo.swipes, hasLength(2), reason: 'yalniz bir yeniden deneme');

      await h.notifier.loadCards();
      await settle();
      expect(h.ids, ['f', 'g', 'h']);
      expect(h.state.swipeLimitHits, 0);
    });
  });
}

const _dailyLimit = Failure<SwipeResponse>(
  ServerFailure(code: 'DAILY_LIMIT_EXCEEDED', statusCode: 403, params: {'resource': 'discover'}),
);

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

  /// Doluysa `swipe` yanıtları sırayla buradan gelir (`Result` ya da yolda
  /// bekleyen istek için `Completer<Result>`); bitince [swipeResult].
  final swipeScript = <Object>[];

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
    if (swipeScript.isNotEmpty) {
      final step = swipeScript.removeAt(0);
      if (step is Completer<Result<SwipeResponse>>) return step.future;
      return step as Result<SwipeResponse>;
    }
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
