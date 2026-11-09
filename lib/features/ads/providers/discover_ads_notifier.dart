import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/native_ad_handle.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/ads/analytics/ad_analytics.dart';
import 'package:qulo_v2/features/ads/domain/ad_audience.dart';
import 'package:qulo_v2/features/ads/domain/ad_slot_rules.dart';
import 'package:qulo_v2/features/ads/providers/ad_audience_provider.dart';
import 'package:qulo_v2/features/ads/providers/discover_ad_loader.dart';
import 'package:qulo_v2/features/ads/providers/discover_ads_state.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

final adAnalyticsProvider = Provider<AdAnalytics>((_) => AdAnalytics());

/// Discover destesine karışan native reklam yuvalarını yönetir.
///
/// Deste ([discoverProvider]) YALNIZ dinlenir: reklam swipe API'sine gitmez,
/// undo yığınına girmez, "seen" listesine yazılmaz. Geçilen profil, destenin
/// başındaki kartın kuyruktan düşmesinden anlaşılır (undo ve prefetch sayılmaz).
///
/// Yüklü reklamın sahibi [_ad] alanıdır, `state.ad` yalnız UI görünümüdür.
/// `onDispose` içinde `state` OKUNMAZ: oturum değişiminde (auth select) Riverpod
/// dispose listesini dolaşırken `state` okuması build'i yeniden tetikler ve
/// listeye yeni dinleyici ekler → ConcurrentModificationError (2.0.16 crash'i).
class DiscoverAdsNotifier extends Notifier<DiscoverAdsState> {
  static const _rules = AdSlotRules();
  NativeAdHandle? _ad;
  int _session = 0; // her dispose'da artar; eski oturumun yüklemesi yeniye sızmaz
  late final AdAnalytics _analytics = ref.read(adAnalyticsProvider);

  @override
  DiscoverAdsState build() {
    ref.watch(authProvider.select((s) => s.status)); // çıkış/giriş → oturum sıfırlanır
    ref.onDispose(() {
      _session++;
      _ad?.dispose();
      _ad = null;
    });
    ref.listen(discoverProvider, _onDeckChanged);
    ref.listen<AsyncValue<AdAudience>>(adAudienceProvider, (_, _) => _discardIfNotAllowed());
    ref.listen<bool>(adsEnabledProvider, (_, _) => _discardIfNotAllowed());
    return const DiscoverAdsState();
  }

  bool get _mayServe => _rules.mayServe(
        audience: ref.read(adAudienceProvider).valueOrNull ?? AdAudience.unknown,
        remoteEnabled: ref.read(adsEnabledProvider),
      );

  /// Kullanıcı reklam kartını geçti / kapattı.
  void dismiss() {
    _ad?.dispose();
    _ad = null;
    state = state.copyWith(clearAd: true, isShowing: false);
  }

  void _onDeckChanged(AsyncValue<DiscoverState>? prev, AsyncValue<DiscoverState> next) {
    final nextCards = next.valueOrNull?.cards;
    if (nextCards == null) return; // yükleniyor / hata: geçiş sayılmaz
    final prevCards = prev?.valueOrNull?.cards ?? const <ProfileCardModel>[];
    final passed = prevCards.isNotEmpty && !nextCards.any((c) => c.userId == prevCards.first.userId);
    final refilled = prevCards.isEmpty && nextCards.isNotEmpty;
    if (!passed && !refilled) return;
    if (passed) state = state.copyWith(profilesPassed: state.profilesPassed + 1);
    _evaluate(hasNextCard: nextCards.isNotEmpty);
  }

  void _evaluate({required bool hasNextCard}) {
    if (state.isShowing || !_mayServe) return;
    final due = _rules.isSlotDue(
      profilesPassed: state.profilesPassed,
      slotsResolved: state.slotsResolved,
      adsShown: state.adsShown,
      hasNextCard: hasNextCard,
    );
    if (due && state.ad != null) return _show();
    if (due && !state.isLoading) {
      state = state.copyWith(slotsResolved: state.slotsResolved + 1); // yüklenemedi → yuva atlanır
    } else if (!due && state.ad == null && !state.isLoading && _rules.shouldPreload(
      profilesPassed: state.profilesPassed,
      slotsResolved: state.slotsResolved,
      adsShown: state.adsShown,
    )) {
      _load();
    }
  }

  void _show() {
    _analytics.slotShown();
    state = state.copyWith(
      isShowing: true,
      slotsResolved: state.slotsResolved + 1,
      adsShown: state.adsShown + 1,
    );
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final loader = DiscoverAdLoader(
      manager: ref.read(admobManagerProvider),
      att: ref.read(attManagerProvider),
      analytics: _analytics,
    );
    final session = _session;
    final handle = await loader.load(stillAllowed: () => session == _session && _mayServe);
    if (session != _session) return handle?.dispose(); // oturum bitti / provider kapandı
    if (handle != null && !_mayServe) handle.dispose();
    _ad = _mayServe ? handle : null;
    state = state.copyWith(isLoading: false, ad: _ad);
  }

  /// VIP olundu / uzaktan kapandı / oturum bitti: yüklü ya da gösterilen reklam atılır.
  void _discardIfNotAllowed() {
    if (_mayServe || (state.ad == null && !state.isShowing)) return;
    dismiss();
  }
}

final discoverAdsProvider = NotifierProvider<DiscoverAdsNotifier, DiscoverAdsState>(
  DiscoverAdsNotifier.new,
);
