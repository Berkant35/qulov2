import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class RedemptionsState extends Equatable {
  const RedemptionsState({
    required this.items,
    required this.total,
    required this.page,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Redemption> items;
  final int total;
  final int page;
  final bool isLoadingMore;

  /// Son sayfa isteği başarısız: kaydırma kendiliğinden tekrar denemez, listenin sonunda
  /// "Yeniden dene" görünür (bkz. [RedemptionsNotifier.retryLoadMore]).
  final bool loadMoreFailed;

  bool get hasMore => items.length < total;

  RedemptionsState copyWith({
    List<Redemption>? items,
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) =>
      RedemptionsState(
        items: items ?? this.items,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );

  @override
  List<Object?> get props => [items, total, page, isLoadingMore, loadMoreFailed];
}

/// "Hediye kartlarım" (spec §7.5): sayfalı liste; ekrandan çıkınca atılır, girişte taze yüklenir.
class RedemptionsNotifier extends AutoDisposeAsyncNotifier<RedemptionsState> {
  static const pageSize = 20;

  @override
  Future<RedemptionsState> build() => _firstPage();

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncLoading<RedemptionsState>().copyWithPrevious(previous);
    final next = await AsyncValue.guard(_firstPage);
    state = next.hasError ? next.copyWithPrevious(previous) : next;
  }

  Future<RedemptionsState> _firstPage() async {
    final page = await _page(1);
    return RedemptionsState(items: page.items, total: page.total, page: 1);
  }

  /// Kaydırma tetikler. Son istek başarısızsa kendiliğinden tekrar denemez — her kaydırma olayında
  /// yeni istek atılırdı (ağ yokken istek fırtınası); tekrar deneme kullanıcıda ([retryLoadMore]).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadMoreFailed) return;
    await _loadNextPage(current);
  }

  /// Listenin sonundaki "Yeniden dene" (pull-to-refresh de bayrağı sıfırlar: ilk sayfa yeni durum).
  Future<void> retryLoadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _loadNextPage(current.copyWith(loadMoreFailed: false));
  }

  Future<void> _loadNextPage(RedemptionsState current) async {
    if (!current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final next = current.page + 1;
    final result = await ref.read(rewardsRepositoryProvider).getRedemptions(page: next, limit: pageSize);
    state = AsyncData(switch (result) {
      Success(:final data) => current.copyWith(
          items: [...current.items, ...data.items.where((r) => !current.items.any((c) => c.id == r.id))],
          // Boş sayfa = liste bitti: sunucu toplamı eskiyse (ör. silinen kayıt) sonsuz sayfalama olmasın.
          total: data.items.isEmpty ? current.items.length : data.total,
          page: next,
          isLoadingMore: false,
        ),
      Failure() => current.copyWith(isLoadingMore: false, loadMoreFailed: true),
    });
  }

  Future<RedemptionPage> _page(int page) async {
    final result = await ref.read(rewardsRepositoryProvider).getRedemptions(page: page, limit: pageSize);
    return switch (result) {
      Success(:final data) => data,
      Failure(:final failure) => throw failure,
    };
  }
}

final redemptionsProvider =
    AsyncNotifierProvider.autoDispose<RedemptionsNotifier, RedemptionsState>(RedemptionsNotifier.new);
