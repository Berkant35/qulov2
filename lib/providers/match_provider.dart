import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  bool _isPrefetching = false;

  /// Bu oturumda gösterilmiş TÜM profil id'leri (swipe edilip kuyruktan
  /// çıkanlar dahil). Taze-çek dedup'u buna karşı yapılır; sunucu swipe'ı
  /// henüz işlememişken aynı profili tekrar döndürse de duplicate olmaz.
  final Set<String> _seenUserIds = {};

  @override
  Future<DiscoverState> build() async => const DiscoverState();

  Future<void> loadCards({int page = 1}) async {
    state = const AsyncLoading();
    final result = await ref.read(matchRepositoryProvider).discover(page: page);
    state = result.when(
      success: (response) {
        // Taze başlangıç (ilk yükleme / retry / "tekrar ara") — seen takibini sıfırla.
        _seenUserIds
          ..clear()
          ..addAll(response.cards.map((c) => c.userId));
        return AsyncData(DiscoverState(
          cards: response.cards,
          page: response.page,
          // Sunucu has_more'u güvenilmez (limit 50 + in-memory filtre → çoğu
          // zaman false). Discover sayfa-tabanlı değil "görülmemiş aday havuzu"
          // tabanlı; ilk batch doluysa taze-çek denemelerine devam edebiliriz.
          hasMore: response.cards.isNotEmpty,
          initialized: true,
        ));
      },
      failure: (f) => AsyncError(f, StackTrace.current),
    );
    // İlk batch küçükse prefetch zincirini hemen başlat.
    _maybePrefetch();
  }

  /// Kart kuyruğu azaldığında (son ~3 kart kala) bir sonraki sayfayı arka
  /// planda çeker; kuyruk boşken (hasMore varken) otomatik doldurur ki
  /// kullanıcı "tekrar ara" boş ekranına düşüp manuel butona basmasın.
  Future<void> maybePrefetch() => _maybePrefetch();

  Future<void> _maybePrefetch() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _isPrefetching) return;
    // Son 3 karta kadar buffer — network gecikmesinde kuyruk boşalmasın.
    if (current.cards.length > 3) return;

    _isPrefetching = true;
    _updatePrefetchingState(true);
    try {
      // Sunucu her discover çağrısında swiped'leri eler ve (ORDER BY olmadan)
      // taze bir aday havuzu döndürür — page+1 boş döner. Bu yüzden her zaman
      // page=1 çekip mevcut kartlarla dedup ederek yeni gelenleri ekleriz.
      final result = await ref.read(matchRepositoryProvider).discover(page: 1);
      result.when(
        success: (response) {
          final latest = state.valueOrNull;
          if (latest != null) {
            // Dedup, bu oturumda gösterilmiş TÜM id'lere karşı (swipe edilip
            // kuyruktan çıkanlar dahil) — yoksa sunucu işlenmemiş swipe'ı
            // tekrar döndürünce aynı profil ikinci kez eklenirdi.
            final fresh = response.cards
                .where((c) => !_seenUserIds.contains(c.userId))
                .toList();
            _seenUserIds.addAll(fresh.map((c) => c.userId));
            state = AsyncData(latest.copyWith(
              cards: [...latest.cards, ...fresh],
              // Taze (dedup sonrası yeni) kart geldiyse havuz devam edebilir;
              // gelmediyse tükendi → dur (sonsuz prefetch önle).
              hasMore: fresh.isNotEmpty,
              isPrefetching: false,
            ));
          }
        },
        failure: (f) {
          dev.log('prefetch failed: $f', name: 'DiscoverNotifier');
          // Ağ hatasında otomatik tetik (empty+hasMore) her rebuild'de yeniden
          // istek atıp sonsuz retry döngüsüne girmesin → hasMore'u kapat.
          // Kullanıcı "tekrar ara"/pull-to-refresh ile loadCards çağırınca sıfırlanır.
          final latest = state.valueOrNull;
          if (latest != null) {
            state = AsyncData(latest.copyWith(hasMore: false, isPrefetching: false));
          }
        },
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
      failure: (f) => dev.log('swipe failed: $f', name: 'DiscoverNotifier'),
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
      failure: (f) => dev.log('undoSwipe failed: $f', name: 'DiscoverNotifier'),
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
  final List<RealtimeChannel> _channels = [];
  int _generation = 0;
  int _retryCount = 0;
  static const _maxRetries = 3;

  @override
  Future<List<MatchModel>> build() async {
    _generation++;
    _retryCount = 0;

    ref.onDispose(_unsubscribeAll);

    final result = await ref.read(matchRepositoryProvider).getMatches();
    final matches = result.when(
      success: (data) => data,
      failure: (f) => throw f,
    );

    Future.microtask(() => _subscribeToRealtime());

    return _sortMatches(matches);
  }

  Future<void> fetchMatches() async {
    state = const AsyncLoading();
    final result = await ref.read(matchRepositoryProvider).getMatches();
    state = result.when(
      success: (data) => AsyncData(_sortMatches(data)),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
    _unsubscribeAll();
    _retryCount = 0;
    _subscribeToRealtime();
  }

  Future<void> silentRefresh() async {
    final result = await ref.read(matchRepositoryProvider).getMatches();
    result.when(
      success: (data) => state = AsyncData(_sortMatches(data)),
      failure: (_) {},
    );
  }

  Future<Result<void>> unmatch(String matchId) async {
    final result = await ref.read(matchRepositoryProvider).unmatch(matchId);
    result.when(
      success: (_) => fetchMatches(),
      failure: (f) => dev.log('unmatch failed: $f', name: 'MatchListNotifier'),
    );
    return result;
  }

  /// Chat ekranı açıldığında badge'i anında sıfırlar (realtime'a bağımlı değil).
  void clearUnreadCount(String matchId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.map((m) {
      if (m.matchId != matchId || m.unreadCount == 0) return m;
      return m.copyWith(unreadCount: 0);
    }).toList();

    state = AsyncData(updated);
  }

  // --- Sorting ---

  List<MatchModel> _sortMatches(List<MatchModel> matches) {
    return [...matches]..sort((a, b) {
      final aTime = a.lastMessageSentAt;
      final bTime = b.lastMessageSentAt;
      if (aTime != null && bTime != null) return bTime.compareTo(aTime);
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return b.matchedAt.compareTo(a.matchedAt);
    });
  }

  // --- Realtime Event Handlers ---

  void _onNewMessage(int gen, PostgresChangePayload payload) {
    if (gen != _generation) return;
    final current = state.valueOrNull;
    if (current == null) return;

    final record = payload.newRecord;
    final matchId = record['match_id'] as String?;
    final senderId = record['sender_id'] as String?;
    final content = record['content'] as String?;
    final createdAt = record['created_at'] as String?;
    final myId = ref.read(authProvider).userId;

    if (matchId == null) return;

    final updated = current.map((m) {
      if (m.matchId != matchId) return m;
      if (createdAt != null && m.lastMessageSentAt != null && createdAt.compareTo(m.lastMessageSentAt!) <= 0) return m;
      return m.copyWith(
        lastMessage: content,
        lastMessageSentAt: createdAt,
        lastMessageSenderId: senderId,
        unreadCount: (senderId != myId) ? m.unreadCount + 1 : m.unreadCount,
      );
    }).toList();

    state = AsyncData(_sortMatches(updated));
  }

  void _onMessageRead(int gen, PostgresChangePayload payload) {
    if (gen != _generation) return;
    final current = state.valueOrNull;
    if (current == null) return;

    final record = payload.newRecord;
    final matchId = record['match_id'] as String?;
    final readAt = record['read_at'];
    final senderId = record['sender_id'] as String?;
    final myId = ref.read(authProvider).userId;

    if (matchId == null || readAt == null) return;
    if (senderId == myId) return;

    final updated = current.map((m) {
      if (m.matchId != matchId || m.unreadCount == 0) return m;
      return m.copyWith(unreadCount: 0);
    }).toList();

    state = AsyncData(updated);
  }

  void _onUserStatusChange(int gen, PostgresChangePayload payload) {
    if (gen != _generation) return;
    final current = state.valueOrNull;
    if (current == null) return;

    final record = payload.newRecord;
    final userId = record['id'] as String?;
    final isOnline = record['is_online'] as bool?;

    if (userId == null || isOnline == null) return;

    final updated = current.map((m) {
      if (m.user?.userId != userId) return m;
      return m.copyWith(user: m.user!.copyWith(isOnline: isOnline));
    }).toList();

    state = AsyncData(updated);
  }

  void _onNewMatch(int gen, PostgresChangePayload payload) {
    if (gen != _generation) return;
    final record = payload.newRecord;
    final user1 = record['user1_id'] as String?;
    final user2 = record['user2_id'] as String?;
    final myId = ref.read(authProvider).userId;

    if (myId == user1 || myId == user2) {
      silentRefresh();
    }
  }

  // --- Subscription Management ---

  void _subscribeToRealtime() {
    final gen = _generation;
    final current = state.valueOrNull;
    if (current == null || current.isEmpty) {
      _subscribeNewMatches(gen);
      return;
    }

    final matchIds = current.map((m) => m.matchId).toList();
    final userIds = current.where((m) => m.user != null).map((m) => m.user!.userId).toList();

    // Channel 1: New messages
    final msgChannel = Supabase.instance.client
        .channel('matches:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.inFilter,
            column: 'match_id',
            value: matchIds,
          ),
          callback: (payload) => _onNewMessage(gen, payload),
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            _handleReconnect();
          }
        });
    _channels.add(msgChannel);

    // Channel 2: Read receipts
    final readChannel = Supabase.instance.client
        .channel('matches:read')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.inFilter,
            column: 'match_id',
            value: matchIds,
          ),
          callback: (payload) => _onMessageRead(gen, payload),
        )
        .subscribe();
    _channels.add(readChannel);

    // Channel 3: Online status
    if (userIds.isNotEmpty) {
      final onlineChannel = Supabase.instance.client
          .channel('matches:online')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.inFilter,
              column: 'id',
              value: userIds,
            ),
            callback: (payload) => _onUserStatusChange(gen, payload),
          )
          .subscribe();
      _channels.add(onlineChannel);
    }

    // Channel 4: New matches
    _subscribeNewMatches(gen);
  }

  void _subscribeNewMatches(int gen) {
    final newMatchChannel = Supabase.instance.client
        .channel('matches:new')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'matches',
          callback: (payload) => _onNewMatch(gen, payload),
        )
        .subscribe();
    _channels.add(newMatchChannel);
  }

  void _unsubscribeAll() {
    _generation++;
    for (final channel in _channels) {
      channel.unsubscribe();
    }
    _channels.clear();
  }

  Future<void> _handleReconnect() async {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    final delay = Duration(seconds: 5 * _retryCount);
    await Future.delayed(delay);
    _unsubscribeAll();
    await silentRefresh();
    _subscribeToRealtime();
  }
}

final matchListProvider = AsyncNotifierProvider<MatchListNotifier, List<MatchModel>>(MatchListNotifier.new);
