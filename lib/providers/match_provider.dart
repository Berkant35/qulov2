import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/realtime_channel_group.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/features/discover/domain/reject_delivery.dart';
import 'package:qulo_v2/features/discover/utils/discover_filter_key.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_list_realtime.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Karşılıklı eşleşme guard'ı (qulo-server `pair-compatibility.service`): hedef
/// izleyiciyle uyumsuzsa / gösterilmemiş, engelli ya da silinmiş profile LIKE ve
/// quiz başlatma erişilemez: yeni sunucu tek tip 404 `USER_NOT_FOUND`, eski sunucu
/// 403 `NOT_COMPATIBLE` döner; ikisi de "profil kullanılamıyor" demektir.
const notCompatibleCode = 'NOT_COMPATIBLE';
const userNotFoundCode = 'USER_NOT_FOUND';

bool isNotCompatibleFailure(AppFailure failure) =>
    failure is ServerFailure && (failure.code == notCompatibleCode || failure.code == userNotFoundCode);

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  bool _isPrefetching = false;

  /// Bu oturumda gösterilmiş TÜM profil id'leri (swipe edilip kuyruktan
  /// çıkanlar dahil). Taze-çek dedup'u buna karşı yapılır; sunucu swipe'ı
  /// henüz işlememişken aynı profili tekrar döndürse de duplicate olmaz.
  final Set<String> _seenUserIds = {};

  /// Bu oturumda reddedilen id'ler. REJECT sunucuya "gönder ve unut" gider;
  /// kayıt düşmeden "Yeniden Ara" aynı kişiyi tekrar getirebilir (prod: hedef,
  /// REJECT insert'inden saniyeler önce yeniden servis edildi). [loadCards]
  /// bunu SIFIRLAMAZ; yalnız geri alma ve günlük hak 403'ü çıkarır.
  final Set<String> _rejectedIds = {};

  /// [DiscoverState.swipeLimitHits]'in kaynağı: yükleme sırasında da artabilir,
  /// yeni deste durumu onu buradan taşır.
  int _swipeLimitHits = 0;

  @override
  Future<DiscoverState> build() async {
    // Notifier örneği yeniden kurulumda (çıkışta invalidate) korunur.
    _rejectedIds.clear();
    _reloadOnFilterChange();
    return DiscoverState(swipeLimitHits: _swipeLimitHits);
  }

  /// Cinsiyet tercihi ayarlanmadan sunucu discover'a PROFILE_INCOMPLETE döner
  /// (qulo-server 14a1f0a). Eskiden giriş ön-yüklemesi tercih seçilmeden
  /// çağrılıp yanlış cinsiyetten deste çekiyordu — tercih yoksa istek atılmaz;
  /// deste tercih ayarlanınca [_reloadOnFilterChange] ile yüklenir.
  bool get _hasGenderPrefOrUnknown {
    final user = ref.read(userProvider).valueOrNull;
    return user == null || user.hasGenderPref;
  }

  /// Adayı sunucuda ELEYEN bir tercih ([DiscoverFilterKey]: cinsiyet tercihi,
  /// dil listesi, yaş aralığı) ilk kez ayarlandığında ya da değiştiğinde desteyi
  /// yeniler. Discover ekranı sekme yığınında canlı kaldığı için oradan açılan
  /// profil düzenlemeden dönüş desteyi kendiliğinden tazelemez (11 Eki: boş dil
  /// durumundan dil ekleyen kullanıcı eski boş desteyi görüyordu).
  /// Kullanıcı verisinin ilk gelişi (null → değer) ve çıkış (değer → null)
  /// yükleme sebebi değildir; konum yoksa yükleme Discover ekranının işidir.
  void _reloadOnFilterChange() {
    ref.listen<DiscoverFilterKey?>(
      userProvider.select((u) => discoverFilterKey(u.valueOrNull)),
      (prev, next) {
        if (prev == null || next == null || prev == next) return;
        if (ref.read(locationProvider).lat == null) return;
        loadCards();
      },
    );
  }

  Future<void> loadCards({int page = 1}) async {
    if (!_hasGenderPrefOrUnknown) return;
    state = const AsyncLoading();
    final result = await ref.read(matchRepositoryProvider).discover(page: page);
    state = result.when(
      success: (response) {
        // Taze başlangıç (ilk yükleme / retry / "tekrar ara") — seen takibini
        // sıfırla; reddedilenler oturum boyu "görüldü" kalır.
        _seenUserIds
          ..clear()
          ..addAll(_rejectedIds)
          ..addAll(response.cards.map((c) => c.userId));
        final cards = response.cards.where((c) => !_rejectedIds.contains(c.userId)).toList();
        return AsyncData(DiscoverState(
          cards: cards,
          page: response.page,
          // Discover sayfa-tabanlı değil "görülmemiş aday havuzu" tabanlı:
          // her çağrı page=1 çekip swipe edilmişleri sunucuda eleyerek kalanın
          // en iyisini döndürür. İlk batch doluysa (süzülse de) taze-çek
          // denemelerine devam; prefetch'te yeni kart yoksa zincir durur.
          hasMore: response.cards.isNotEmpty,
          initialized: true,
          emptyReason: cards.isEmpty ? response.emptyReason : null,
          swipeLimitHits: _swipeLimitHits,
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
              // Sebep, YEREL KUYRUK hakkında değil SUNUCU HAVUZU hakkında bir
              // olgu: "havuzda başka aday yok, sebebi şu". Elde hâlâ kart
              // varken de kaydedilir, çünkü kullanıcı o kartları da tükettiğinde
              // gösterilecek olan budur. Ekran zaten yalnızca kuyruk boşken okur.
              emptyReason: fresh.isEmpty ? response.emptyReason : null,
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

  /// İyimser red: kart anında çıkar, REJECT arka planda teslim edilir.
  void rejectCard(String targetId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final swipedCard = current.cards.where((c) => c.userId == targetId).firstOrNull;
    if (swipedCard == null) return;

    _rejectedIds.add(targetId);
    final updatedCards = current.cards.where((c) => c.userId != targetId).toList();
    state = AsyncData(current.copyWith(
      cards: updatedCards,
      lastSwipedCard: swipedCard,
    ));
    _maybePrefetch();
    unawaited(_deliverReject(swipedCard));
  }

  Future<void> _deliverReject(ProfileCardModel card) async {
    final repo = ref.read(matchRepositoryProvider);
    final outcome = await RejectDelivery(
      send: (id) => repo.swipe(targetId: id, action: 'REJECT'),
    ).deliver(card.userId, stillRejected: () => _rejectedIds.contains(card.userId));
    switch (outcome) {
      case RejectDeliveryOutcome.delivered:
        return;
      case RejectDeliveryOutcome.limitExceeded:
        _restoreUnrecordedReject(card);
      case RejectDeliveryOutcome.failed:
        // Oturumda geri gelmez (`_rejectedIds`'te kalır).
        dev.log('reject not delivered: ${card.userId}', name: 'DiscoverNotifier');
    }
  }

  /// Günlük hak bitti, red kaydedilmedi: kart destenin başına döner ve ekran
  /// paywall'u açsın diye [DiscoverState.swipeLimitHits] artar. Kart destede
  /// olduğu için `_seenUserIds`'te kalır (prefetch onu ikinci kez eklemesin).
  void _restoreUnrecordedReject(ProfileCardModel card) {
    // Beklerken geri alındıysa kart zaten destede.
    if (!_rejectedIds.remove(card.userId)) return;
    _swipeLimitHits++;
    final current = state.valueOrNull;
    if (current == null) return;
    final inDeck = current.cards.any((c) => c.userId == card.userId);
    state = AsyncData(current.copyWith(
      cards: inDeck ? null : [card, ...current.cards],
      // Kaydı olmayan red geri alınamaz; sonra reddedilen kartın hakkı kalır.
      lastSwipedCard: current.lastSwipedCard?.userId == card.userId ? null : current.lastSwipedCard,
      swipeLimitHits: _swipeLimitHits,
    ));
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
      failure: (f) {
        dev.log('swipe failed: $f', name: 'DiscoverNotifier');
        if (isNotCompatibleFailure(f)) _dropCard(targetId);
      },
    );
    return result;
  }

  /// Uyumsuz kart (404 `USER_NOT_FOUND` / eski 403 `NOT_COMPATIBLE`, ör. sunucu karşılıklı eşleşme anahtarı
  /// açılmadan önce çekilmiş deste) desteden düşer; kalsaydı her dokunuş sessizce
  /// yine reddedilirdi. Geri alınabilir değildir (`lastSwipedCard` değişmez).
  void _dropCard(String targetId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      cards: current.cards.where((c) => c.userId != targetId).toList(),
    ));
    _maybePrefetch();
  }

  Future<Result<ProfileCardModel>> undoSwipe() async {
    final current = state.valueOrNull;
    final lastCard = current?.lastSwipedCard;
    if (lastCard == null) return const Failure(UnknownFailure(message: 'No swipe to undo'));

    final result = await ref.read(matchRepositoryProvider).undoSwipe(lastCard.userId);
    result.when(
      success: (card) {
        // Geri alma swipe'i sunucuda siler: kart yeniden gosterilebilir.
        _rejectedIds.remove(card.userId);
        // Beklerken biten prefetch'in kartlari kaybolmasin: `current` await
        // oncesinin anlik goruntusu, guncel state'in uzerine yazilir.
        final latest = state.valueOrNull;
        if (latest != null) {
          state = AsyncData(latest.copyWith(
            cards: [card, ...latest.cards],
            lastSwipedCard: null,
          ));
        }
      },
      failure: (f) => dev.log('undoSwipe failed: $f', name: 'DiscoverNotifier'),
    );
    return result;
  }
}

/// `copyWith`'te "bu alan gecilmedi" ile "acikca null gecildi"yi ayirt eden nobetci.
const Object _keep = Object();

class DiscoverState {
  final List<ProfileCardModel> cards;
  final int page;
  final bool hasMore;
  final bool initialized;
  final bool isPrefetching;
  final ProfileCardModel? lastSwipedCard;

  /// Sunucu havuzunun neden aday döndürmediği: `DiscoverEmptyReason` değeri.
  /// Yerel kuyruk hakkında değil sunucu havuzu hakkında bir olgu — elde hâlâ
  /// kart varken de dolu olabilir. Ekran yalnızca kuyruk boşken okur.
  final String? emptyReason;

  /// Kaç reddin günlük hak (403 `DAILY_LIMIT_EXCEEDED`) yüzünden sunucuya
  /// düşmediği — oturum boyu artar, hiç sıfırlanmaz. Sağlayıcı UI açmaz:
  /// Discover ekranı artışta günlük sınır paywall'unu açar.
  final int swipeLimitHits;

  const DiscoverState({
    this.cards = const [],
    this.page = 1,
    this.hasMore = false,
    this.initialized = false,
    this.isPrefetching = false,
    this.lastSwipedCard,
    this.emptyReason,
    this.swipeLimitHits = 0,
  });

  bool get canUndo => lastSwipedCard != null;

  DiscoverState copyWith({
    List<ProfileCardModel>? cards,
    int? page,
    bool? hasMore,
    bool? initialized,
    bool? isPrefetching,
    Object? lastSwipedCard = _keep,
    Object? emptyReason = _keep,
    int? swipeLimitHits,
  }) {
    return DiscoverState(
      cards: cards ?? this.cards,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      initialized: initialized ?? this.initialized,
      isPrefetching: isPrefetching ?? this.isPrefetching,
      // emptyReason ile ayni sebep: ciplak atama prefetch bayragi gibi ilgisiz
      // her guncellemede geri alma hakkini siliyordu (kuyrukta <=3 kart varken
      // swipe edilen kart geri alinamiyordu). Temizlemek icin null gecilir.
      lastSwipedCard: identical(lastSwipedCard, _keep)
          ? this.lastSwipedCard
          : lastSwipedCard as ProfileCardModel?,
      // Sebep yalnizca sunucu yaniti isleyen cagrilarda degisir. Swipe/prefetch
      // bayragi gibi ilgisiz guncellemeler onu OLDUGU GIBI birakmali — "?? "
      // yeterli degildi cunku acikca null gecip temizlemeyi de imkansiz kilardi,
      // ciplak atama ise gecmeyen her cagirida sebebi siliyordu (son karti
      // swipe edince dil ekrani hic gorunmuyordu).
      emptyReason: identical(emptyReason, _keep)
          ? this.emptyReason
          : emptyReason as String?,
      swipeLimitHits: swipeLimitHits ?? this.swipeLimitHits,
    );
  }
}

final discoverProvider = AsyncNotifierProvider<DiscoverNotifier, DiscoverState>(DiscoverNotifier.new);

/// Eşleşme listesi + dört Realtime kanalı. Kanalların token'ı, yeniden
/// kurulumu ve kopukluk sonrası tazelemesi [RealtimeChannelGroup]'ta; olayların
/// listeye uygulanışı [MatchListRealtimeReducer]'da.
class MatchListNotifier extends AsyncNotifier<List<MatchModel>> {
  RealtimeChannelGroup? _realtime;

  @override
  Future<List<MatchModel>> build() async {
    // Logout'ta invalidate edilirken alttaki ekranlar hala dinliyor; kimliksizken
    // aga cikma (token'siz istek → 401 → Crashlytics gurultusu).
    final authStatus = ref.watch(authProvider.select((s) => s.status));
    if (authStatus != AuthStatus.authenticated) {
      _realtime = null;
      return const [];
    }

    final realtime = RealtimeChannelGroup(
      auth: ref.read(realtimeAuthManagerProvider),
      userId: ref.read(authProvider).userId ?? '',
      build: _buildChannels,
      reload: silentRefresh,
    );
    _realtime = realtime;
    ref.onDispose(realtime.dispose);

    final result = await ref.read(matchRepositoryProvider).getMatches();
    final matches = result.when(
      success: (data) => data,
      failure: (f) => throw f,
    );

    Future.microtask(realtime.start);

    return _sortMatches(matches);
  }

  Future<void> fetchMatches() async {
    state = const AsyncLoading();
    final result = await ref.read(matchRepositoryProvider).getMatches();
    state = result.when(
      success: (data) => AsyncData(_sortMatches(data)),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
    // Liste değişti: filtreler yeni eşleşme kimlikleriyle kurulur. Yenilemeyi
    // (pull-to-refresh) kanal kurulumu beklemez.
    final realtime = _realtime;
    if (realtime != null) unawaited(realtime.restart(reload: false));
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

  // --- Realtime ---

  List<RealtimeChannel> _buildChannels(int gen, RealtimeStatusCallback onStatus) =>
      buildMatchListChannels(
        client: Supabase.instance.client,
        matches: state.valueOrNull ?? const [],
        generation: gen,
        onStatus: onStatus,
        onNewMessage: (g, p) => _apply(g, (m) => MatchListRealtimeReducer.onNewMessage(m, p.newRecord, myId: _myId), sort: true),
        onMessageRead: (g, p) => _apply(g, (m) => MatchListRealtimeReducer.onMessageRead(m, p.newRecord, myId: _myId)),
        onUserStatus: (g, p) => _apply(g, (m) => MatchListRealtimeReducer.onUserStatus(m, p.newRecord)),
        onNewMatch: (g, p) {
          if (_isCurrent(g) && MatchListRealtimeReducer.isMyNewMatch(p.newRecord, myId: _myId)) {
            silentRefresh();
          }
        },
      );

  String? get _myId => ref.read(authProvider).userId;

  bool _isCurrent(int gen) => gen == _realtime?.generation;

  void _apply(int gen, List<MatchModel> Function(List<MatchModel>) reduce, {bool sort = false}) {
    final current = state.valueOrNull;
    if (!_isCurrent(gen) || current == null) return;
    final updated = reduce(current);
    state = AsyncData(sort ? _sortMatches(updated) : updated);
  }
}

final matchListProvider = AsyncNotifierProvider<MatchListNotifier, List<MatchModel>>(MatchListNotifier.new);
