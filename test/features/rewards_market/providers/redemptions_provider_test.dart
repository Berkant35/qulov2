import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/providers/redemptions_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_repositories.dart';

Redemption _r(String id) => Redemption(id: id, status: RedemptionStatus.pending, brandKey: 'GRAB',
    countryCode: 'TH', currency: 'THB', faceValue: 50, rainbowPrice: 51);

void main() {
  test('ilk sayfa build\'de; loadMore sonraki sayfayı ekler, tekrarı eler, sonda durur', () async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a'), _r('b')], total: 3, page: 1, limit: 2),
      2: RedemptionPage(items: [_r('b'), _r('c')], total: 3, page: 2, limit: 2),
    });
    final container = ProviderContainer(overrides: [rewardsRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(redemptionsProvider, (_, __) {});
    addTearDown(sub.close);

    final first = await container.read(redemptionsProvider.future);
    expect(first.items.map((r) => r.id), ['a', 'b']);
    expect(first.hasMore, isTrue);

    await container.read(redemptionsProvider.notifier).loadMore();
    final second = container.read(redemptionsProvider).requireValue;
    expect(second.items.map((r) => r.id), ['a', 'b', 'c']);
    expect(second.hasMore, isFalse);

    await container.read(redemptionsProvider.notifier).loadMore();
    expect(repo.redemptionPagesRequested, [1, 2]);
  });

  test('loadMore hatası listeyi korur, yükleme bayrağı kalkar', () async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a')], total: 5, page: 1, limit: 1),
    });
    final container = ProviderContainer(overrides: [rewardsRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(redemptionsProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(redemptionsProvider.future);
    repo.redemptionsFailure = const NetworkFailure();
    await container.read(redemptionsProvider.notifier).loadMore();
    final state = container.read(redemptionsProvider).requireValue;
    expect(state.items.map((r) => r.id), ['a']);
    expect(state.isLoadingMore, isFalse);
  });

  test('refresh sürerken önceki öğeler görünür kalır (tam sayfa yükleyiciye düşmez)', () async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a')], total: 1, page: 1, limit: 20),
    });
    final container = ProviderContainer(overrides: [rewardsRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(redemptionsProvider, (_, __) {});
    addTearDown(sub.close);

    final first = await container.read(redemptionsProvider.future);
    expect(first.items.map((r) => r.id), ['a']);

    final gate = Completer<void>();
    repo.redemptionsGate = gate;
    final refreshFuture = container.read(redemptionsProvider.notifier).refresh();

    // refresh() içindeki state ataması ilk await'ten önce senkron çalışır — gate
    // henüz açılmadan hemen kontrol edebiliriz.
    final loading = container.read(redemptionsProvider);
    expect(loading.isLoading, isTrue);
    expect(loading.valueOrNull?.items.map((r) => r.id), ['a']);

    gate.complete();
    await refreshFuture;
    expect(container.read(redemptionsProvider).requireValue.items.map((r) => r.id), ['a']);
  });

  test('refresh hatası önceki öğeleri korur', () async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a')], total: 1, page: 1, limit: 20),
    });
    final container = ProviderContainer(overrides: [rewardsRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(redemptionsProvider, (_, __) {});
    addTearDown(sub.close);

    final first = await container.read(redemptionsProvider.future);
    expect(first.items.map((r) => r.id), ['a']);

    repo.redemptionsFailure = const NetworkFailure();
    await container.read(redemptionsProvider.notifier).refresh();

    final state = container.read(redemptionsProvider);
    expect(state.hasError, isTrue);
    expect(state.valueOrNull?.items.map((r) => r.id), ['a']);
  });

  test('loadMore boş sayfa dönerse sayfalama durur (sunucu toplamı eskiyse sonsuz istek yok)', () async {
    final repo = FakeRewardsRepository(redemptionPages: {
      1: RedemptionPage(items: [_r('a')], total: 5, page: 1, limit: 1),
      2: const RedemptionPage(items: [], total: 5, page: 2, limit: 1),
    });
    final container = ProviderContainer(overrides: [rewardsRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final sub = container.listen(redemptionsProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(redemptionsProvider.future);

    await container.read(redemptionsProvider.notifier).loadMore();
    final state = container.read(redemptionsProvider).requireValue;
    expect(state.items.map((r) => r.id), ['a']);
    expect(state.hasMore, isFalse);

    await container.read(redemptionsProvider.notifier).loadMore();
    expect(repo.redemptionPagesRequested, [1, 2]);
  });

  group('loadMore hatası sonrası tekrar deneme kullanıcı eylemine bağlı', () {
    late FakeRewardsRepository repo;
    late ProviderContainer container;

    setUp(() async {
      repo = FakeRewardsRepository(redemptionPages: {
        1: RedemptionPage(items: [_r('a')], total: 2, page: 1, limit: 1),
        2: RedemptionPage(items: [_r('b')], total: 2, page: 2, limit: 1),
      });
      container = ProviderContainer(overrides: [rewardsRepositoryProvider.overrideWithValue(repo)]);
      addTearDown(container.dispose);
      final sub = container.listen(redemptionsProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(redemptionsProvider.future);
      repo.redemptionsFailure = const NetworkFailure();
      await container.read(redemptionsProvider.notifier).loadMore();
    });

    test('hata bayrağı kalkar; sonraki kaydırmalar istek ATMAZ (ağ yokken istek fırtınası yok)', () async {
      expect(container.read(redemptionsProvider).requireValue.loadMoreFailed, isTrue);

      final notifier = container.read(redemptionsProvider.notifier);
      await notifier.loadMore();
      await notifier.loadMore();
      await notifier.loadMore();

      expect(repo.redemptionPagesRequested, [1, 2], reason: 'yalnız ilk başarısız deneme');
    });

    test('retryLoadMore aynı sayfayı yeniden ister; başarıda bayrak iner, öğe eklenir', () async {
      repo.redemptionsFailure = null;
      await container.read(redemptionsProvider.notifier).retryLoadMore();

      final state = container.read(redemptionsProvider).requireValue;
      expect(repo.redemptionPagesRequested, [1, 2, 2]);
      expect(state.items.map((r) => r.id), ['a', 'b']);
      expect(state.loadMoreFailed, isFalse);
    });

    test('retryLoadMore yine başarısızsa bayrak kalır, kaydırma yine istek atmaz', () async {
      await container.read(redemptionsProvider.notifier).retryLoadMore();
      await container.read(redemptionsProvider.notifier).loadMore();

      expect(repo.redemptionPagesRequested, [1, 2, 2]);
      expect(container.read(redemptionsProvider).requireValue.loadMoreFailed, isTrue);
    });

    test('pull-to-refresh bayrağı sıfırlar: kaydırma yeniden sayfa ister', () async {
      repo.redemptionsFailure = null;
      await container.read(redemptionsProvider.notifier).refresh();
      expect(container.read(redemptionsProvider).requireValue.loadMoreFailed, isFalse);

      await container.read(redemptionsProvider.notifier).loadMore();
      expect(repo.redemptionPagesRequested, [1, 2, 1, 2]);
    });
  });
}
