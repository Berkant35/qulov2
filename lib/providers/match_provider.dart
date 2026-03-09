import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  @override
  Future<DiscoverState> build() async => const DiscoverState();

  Future<void> loadCards({int page = 1}) async {
    state = const AsyncLoading();
    final result = await ref.read(matchRepositoryProvider).discover(page: page);
    state = result.when(
      success: (response) => AsyncData(DiscoverState(
        cards: response.cards,
        page: response.page,
        hasMore: response.hasMore,
      )),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async {
    final result = await ref.read(matchRepositoryProvider).swipe(targetId: targetId, action: action);
    result.when(
      success: (_) {
        final current = state.valueOrNull;
        if (current != null) {
          final updatedCards = current.cards.where((c) => c.userId != targetId).toList();
          state = AsyncData(current.copyWith(cards: updatedCards));
        }
      },
      failure: (_) {},
    );
    return result;
  }
}

class DiscoverState {
  final List<ProfileCardModel> cards;
  final int page;
  final bool hasMore;

  const DiscoverState({this.cards = const [], this.page = 1, this.hasMore = false});

  DiscoverState copyWith({List<ProfileCardModel>? cards, int? page, bool? hasMore}) {
    return DiscoverState(
      cards: cards ?? this.cards,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final discoverProvider = AsyncNotifierProvider<DiscoverNotifier, DiscoverState>(DiscoverNotifier.new);

class MatchListNotifier extends AsyncNotifier<List<MatchModel>> {
  @override
  Future<List<MatchModel>> build() async => [];

  Future<void> fetchMatches() async {
    state = const AsyncLoading();
    final result = await ref.read(matchRepositoryProvider).getMatches();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<Result<void>> unmatch(String matchId) async {
    final result = await ref.read(matchRepositoryProvider).unmatch(matchId);
    result.when(success: (_) => fetchMatches(), failure: (_) {});
    return result;
  }
}

final matchListProvider = AsyncNotifierProvider<MatchListNotifier, List<MatchModel>>(MatchListNotifier.new);
