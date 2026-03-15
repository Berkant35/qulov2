import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  bool _isPrefetching = false;

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
        initialized: true,
      )),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<void> _maybePrefetch() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isPrefetching) return;
    if (current.cards.length > 2) return;

    _isPrefetching = true;
    _updatePrefetchingState(true);
    try {
      final result = await ref.read(matchRepositoryProvider).discover(page: current.page + 1);
      result.when(
        success: (response) {
          final latest = state.valueOrNull;
          if (latest != null) {
            state = AsyncData(latest.copyWith(
              cards: [...latest.cards, ...response.cards],
              page: response.page,
              hasMore: response.hasMore,
              isPrefetching: false,
            ));
          }
        },
        failure: (_) => _updatePrefetchingState(false),
      );
    } finally {
      _isPrefetching = false;
    }
  }

  void _updatePrefetchingState(bool value) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isPrefetching: value));
    }
  }

  /// Optimistic reject — removes card instantly, fires API in background.
  void rejectCard(String targetId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final swipedCard = current.cards.where((c) => c.userId == targetId).firstOrNull;
    if (swipedCard == null) return;

    final updatedCards = current.cards.where((c) => c.userId != targetId).toList();
    state = AsyncData(current.copyWith(
      cards: updatedCards,
      lastSwipedCard: swipedCard,
    ));
    _maybePrefetch();

    // Fire-and-forget — reject failure is not critical
    ref.read(matchRepositoryProvider).swipe(targetId: targetId, action: 'REJECT');
  }

  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async {
    final result = await ref.read(matchRepositoryProvider).swipe(targetId: targetId, action: action);
    result.when(
      success: (_) {
        final current = state.valueOrNull;
        if (current != null) {
          final swipedCard = current.cards.where((c) => c.userId == targetId).firstOrNull;
          final updatedCards = current.cards.where((c) => c.userId != targetId).toList();
          state = AsyncData(current.copyWith(
            cards: updatedCards,
            lastSwipedCard: swipedCard,
          ));
          _maybePrefetch();
        }
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<ProfileCardModel>> undoSwipe() async {
    final current = state.valueOrNull;
    final lastCard = current?.lastSwipedCard;
    if (lastCard == null) return const Failure(UnknownFailure(message: 'No swipe to undo'));

    final result = await ref.read(matchRepositoryProvider).undoSwipe(lastCard.userId);
    result.when(
      success: (card) {
        if (current != null) {
          state = AsyncData(current.copyWith(
            cards: [card, ...current.cards],
            lastSwipedCard: null,
          ));
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
  final bool initialized;
  final bool isPrefetching;
  final ProfileCardModel? lastSwipedCard;

  const DiscoverState({
    this.cards = const [],
    this.page = 1,
    this.hasMore = false,
    this.initialized = false,
    this.isPrefetching = false,
    this.lastSwipedCard,
  });

  bool get canUndo => lastSwipedCard != null;

  DiscoverState copyWith({
    List<ProfileCardModel>? cards,
    int? page,
    bool? hasMore,
    bool? initialized,
    bool? isPrefetching,
    ProfileCardModel? lastSwipedCard,
  }) {
    return DiscoverState(
      cards: cards ?? this.cards,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      initialized: initialized ?? this.initialized,
      isPrefetching: isPrefetching ?? this.isPrefetching,
      lastSwipedCard: lastSwipedCard,
    );
  }
}

final discoverProvider = AsyncNotifierProvider<DiscoverNotifier, DiscoverState>(DiscoverNotifier.new);

class MatchListNotifier extends AsyncNotifier<List<MatchModel>> {
  @override
  Future<List<MatchModel>> build() async {
    final result = await ref.read(matchRepositoryProvider).getMatches();
    return result.when(
      success: (data) => data,
      failure: (f) => throw f,
    );
  }

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
