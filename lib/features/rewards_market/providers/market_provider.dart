import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Tazelik hesabının saati (testte sabitlenir).
final marketClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Market ekranı durumu (spec §7.2): 60 sn tazelik, zorla yenileme, test admin önizleme ülkesi.
/// Yenileme hatasında önceki veri korunur (`copyWithPrevious`) — ekran boşalmaz; erişim kapandıysa
/// (`RAINBOW_NOT_AVAILABLE`) korunmaz. Başarılı yükleme Rainbow bakiyesini kullanıcıya da yazar
/// (üst çubuk çipi ile market aynı sayıyı gösterir).
class MarketNotifier extends AsyncNotifier<MarketView?> {
  static const freshFor = Duration(seconds: 60);

  DateTime? _fetchedAt;
  String? _country;
  Future<void>? _pending;

  /// Riverpod 2 `invalidate`'te notifier örneğini yeniden kullanır: çıkışta alanlar `build`'de
  /// sıfırlanır, uçuştaki eski yanıt nesil farkıyla atılır (önceki hesabın verisi yeni oturuma yazılmaz).
  int _generation = 0;

  String? get previewCountry => _country;

  @override
  FutureOr<MarketView?> build() {
    _generation++;
    _fetchedAt = null;
    _country = null;
    _pending = null;
    return null;
  }

  Future<void> load({bool force = false}) {
    final pending = _pending;
    if (pending != null) return pending;
    if (!force && _isFresh) return Future.value();
    late final Future<void> future;
    future = _fetch().whenComplete(() {
      if (identical(_pending, future)) _pending = null;
    });
    return _pending = future;
  }

  Future<void> selectCountry(String? country) async {
    if (country == _country) return;
    _country = country;
    await _pending;
    await load(force: true);
  }

  /// İtfa başarısı: sunucunun döndürdüğü bakiye + bu ay kullanım yerelde (istek yok).
  void applyRedeem({required int balance, required int price}) {
    final view = state.valueOrNull;
    if (view == null) return;
    state = AsyncData(view.copyWith(balance: balance, usedThisMonth: view.usedThisMonth + price));
  }

  bool get _isFresh {
    final fetchedAt = _fetchedAt;
    return state.valueOrNull != null &&
        fetchedAt != null &&
        ref.read(marketClockProvider)().difference(fetchedAt) < freshFor;
  }

  Future<void> _fetch() async {
    final generation = _generation;
    final previous = state.valueOrNull;
    state = previous != null
        ? const AsyncLoading<MarketView?>().copyWithPrevious(AsyncData(previous))
        : const AsyncLoading<MarketView?>();
    final result = await ref.read(rewardsRepositoryProvider).getMarket(country: _country);
    if (generation != _generation) return;
    switch (result) {
      case Success(:final data):
        _fetchedAt = ref.read(marketClockProvider)();
        state = AsyncData(data);
        ref.read(userProvider.notifier).applyRainbow(data.balance);
      case Failure(:final failure) when failure is ServerFailure && failure.code == 'RAINBOW_NOT_AVAILABLE':
        // Erişim kapandı: eski bakiye/katalog taşınmaz. Riverpod 2 her atamada önceki değeri
        // yeni duruma kopyalar (`asyncTransition`) — hatadan önce değer boşaltılır.
        _fetchedAt = null;
        state = const AsyncData(null);
        state = AsyncError(failure, StackTrace.current);
      case Failure(:final failure):
        final error = AsyncError<MarketView?>(failure, StackTrace.current);
        state = previous != null ? error.copyWithPrevious(AsyncData(previous)) : error;
    }
  }
}

final marketProvider = AsyncNotifierProvider<MarketNotifier, MarketView?>(MarketNotifier.new);
