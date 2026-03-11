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
        initialized: true,
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
          // Save the swiped card for potential undo
          final swipedCard = current.cards.where((c) => c.userId == targetId).firstOrNull;
          final updatedCards = current.cards.where((c) => c.userId != targetId).toList();
          state = AsyncData(current.copyWith(
            cards: updatedCards,
            lastSwipedCard: swipedCard,
          ));
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
  final ProfileCardModel? lastSwipedCard;

  const DiscoverState({
    this.cards = const [],
    this.page = 1,
    this.hasMore = false,
    this.initialized = false,
    this.lastSwipedCard,
  });

  bool get canUndo => lastSwipedCard != null;

  DiscoverState copyWith({
    List<ProfileCardModel>? cards,
    int? page,
    bool? hasMore,
    bool? initialized,
    ProfileCardModel? lastSwipedCard,
  }) {
    return DiscoverState(
      cards: cards ?? this.cards,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      initialized: initialized ?? this.initialized,
      lastSwipedCard: lastSwipedCard,
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
