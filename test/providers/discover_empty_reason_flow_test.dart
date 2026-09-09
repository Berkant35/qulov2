import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

/// Sirayla scriptlenmis discover yanitlari doner: once dolu bir sayfa,
/// sonra dil sebebiyle bos.
class _ScriptedMatchRepository implements MatchRepository {
  _ScriptedMatchRepository(this._responses);

  final List<DiscoverResponse> _responses;
  int _index = 0;

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    final res = _responses[_index.clamp(0, _responses.length - 1)];
    _index++;
    return Success(res);
  }

  @override
  Future<Result<SwipeResponse>> swipe({
    required String targetId,
    required String action,
  }) async =>
      const Success(SwipeResponse(matched: false));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_ScriptedMatchRepository.${invocation.memberName}');
}

ProfileCardModel _card(String id) =>
    ProfileCardModel(userId: id, questionCount: 2, distanceKm: 10, distanceTier: 0);

void main() {
  test(
    'son kart swipe edilince dil sebebi silinmez — bos ekran dogru varyanti gosterir',
    () async {
      // Gercek akis: elde tek kart varken prefetch tetiklenir, sunucu dil
      // sebebiyle bos doner (hasMore=false). Kullanici son karti swipe eder.
      // Bu noktada sebep hala 'language' olmali; aksi halde ekran radius
      // slider'li genel bos durumu gosterir ve ozelligin ana senaryosu
      // (havuz dil kapisi yuzunden tukendi) hic calismaz.
      final repo = _ScriptedMatchRepository([
        DiscoverResponse(cards: [_card('a')], page: 1, hasMore: true),
        const DiscoverResponse(
          cards: [],
          page: 1,
          hasMore: false,
          emptyReason: DiscoverEmptyReason.language,
        ),
      ]);

      final container = ProviderContainer(overrides: [
        matchRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(discoverProvider.notifier);
      await container.read(discoverProvider.future);

      await notifier.loadCards();
      // loadCards sonrasi prefetch zinciri tetiklenir (tek kart <= 3 buffer).
      await notifier.maybePrefetch();

      final beforeSwipe = container.read(discoverProvider).valueOrNull!;
      expect(beforeSwipe.emptyReason, DiscoverEmptyReason.language);
      expect(beforeSwipe.cards, hasLength(1));

      notifier.rejectCard('a');

      final afterSwipe = container.read(discoverProvider).valueOrNull!;
      expect(afterSwipe.cards, isEmpty);
      expect(
        afterSwipe.emptyReason,
        DiscoverEmptyReason.language,
        reason: 'ilgisiz bir state guncellemesi sebebi silmemeli',
      );
    },
  );

  test('kart gelen yanit sebebi temizler', () async {
    final repo = _ScriptedMatchRepository([
      const DiscoverResponse(
        cards: [],
        page: 1,
        hasMore: false,
        emptyReason: DiscoverEmptyReason.noCandidates,
      ),
      DiscoverResponse(cards: [_card('a')], page: 1, hasMore: true),
    ]);

    final container = ProviderContainer(overrides: [
      matchRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(discoverProvider.notifier);
    await container.read(discoverProvider.future);

    await notifier.loadCards();
    expect(
      container.read(discoverProvider).valueOrNull!.emptyReason,
      DiscoverEmptyReason.noCandidates,
    );

    // Ikinci yukleme kart getiriyor — sebep temizlenmeli.
    await notifier.loadCards();
    final after = container.read(discoverProvider).valueOrNull!;
    expect(after.cards, hasLength(1));
    expect(after.emptyReason, isNull);
  });
}
