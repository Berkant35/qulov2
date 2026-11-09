import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/native_ad_handle.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/features/ads/analytics/ad_analytics.dart';
import 'package:qulo_v2/features/ads/domain/ad_audience.dart';
import 'package:qulo_v2/features/ads/providers/ad_audience_provider.dart';
import 'package:qulo_v2/features/ads/providers/discover_ads_notifier.dart';
import 'package:qulo_v2/features/ads/providers/discover_ads_state.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

import 'ad_test_support.dart';

/// Discover reklam yuvaları — deste entegrasyonu.
///
/// KRİTİK: (1) VIP/bilinmeyen/kapalıda ne istek ne gösterim, (2) reklam kartı
/// swipe API'sine gitmez, undo yığınına girmez, desteyi değiştirmez.
class _AuthedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);

  /// Gerçek `logout()` ile aynı geçiş: status → unauthenticated.
  void signOut() => state = const AuthState(status: AuthStatus.unauthenticated);
}

final _audienceSource = StateProvider<AdAudience>((_) => AdAudience.free);

ProfileCardModel _card(String id) =>
    ProfileCardModel(userId: id, questionCount: 2, distanceKm: 10, distanceTier: 0);

class _FakeMatchRepository implements MatchRepository {
  _FakeMatchRepository(this.ids);
  final List<String> ids;
  final swipes = <String>[];
  int undoCalls = 0;

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async =>
      Success(DiscoverResponse(cards: [for (final id in ids) _card(id)], page: 1, hasMore: true));

  @override
  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async {
    swipes.add('$action:$targetId');
    return const Success(SwipeResponse(matched: false));
  }

  @override
  Future<Result<ProfileCardModel>> undoSwipe(String targetId) async {
    undoCalls++;
    return Success(_card(targetId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeMatchRepository.${invocation.memberName}');
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness._(this.repo, this.admob, this.events, this.container);

  final _FakeMatchRepository repo;
  final FakeAdMob admob;
  final List<String> events;
  final ProviderContainer container;

  static Future<_Harness> create({
    int cards = 30,
    bool adsEnabled = true,
    AdAudience audience = AdAudience.free,
    bool attAuthorized = true,
    FakeAdMob? admob,
  }) async {
    final repo = _FakeMatchRepository([for (var i = 0; i < cards; i++) 'u$i']);
    final fake = admob ?? FakeAdMob();
    final events = <String>[];
    final container = ProviderContainer(overrides: [
      matchRepositoryProvider.overrideWithValue(repo),
      admobManagerProvider.overrideWithValue(fake),
      attManagerProvider.overrideWithValue(FakeAtt(authorized: attAuthorized)),
      adsEnabledProvider.overrideWithValue(adsEnabled),
      authProvider.overrideWith(_AuthedNotifier.new),
      adAudienceProvider.overrideWith((ref) async => ref.watch(_audienceSource)),
      adAnalyticsProvider.overrideWithValue(
        AdAnalytics(sink: (name, {params}) => events.add(name)),
      ),
    ]);
    addTearDown(container.dispose);
    container.read(_audienceSource.notifier).state = audience;
    container.listen(discoverProvider, (_, _) {});
    container.listen(adAudienceProvider, (_, _) {});
    container.listen(discoverAdsProvider, (_, _) {});
    await container.read(discoverProvider.notifier).loadCards();
    await _settle();
    return _Harness._(repo, fake, events, container);
  }

  DiscoverAdsState get ads => container.read(discoverAdsProvider);
  DiscoverState get deck => container.read(discoverProvider).requireValue;
  List<String> get ids => deck.cards.map((c) => c.userId).toList();

  /// Desteyi başındaki profili reddederek [n] kez ilerletir.
  Future<void> reject(int n) async {
    for (var i = 0; i < n; i++) {
      container.read(discoverProvider.notifier).rejectCard(ids.first);
      await _settle();
    }
  }

  void dismissAd() => container.read(discoverAdsProvider.notifier).dismiss();
}

void main() {
  group('yerleşim', () {
    test('4 profilde reklam yok; 5. profili geçince reklam kartı çıkar', () async {
      final h = await _Harness.create();

      await h.reject(4);
      expect(h.ads.isShowing, isFalse);

      await h.reject(1);
      expect(h.ads.isShowing, isTrue);
      expect(h.ads.adsShown, 1);
      expect(h.events, contains('ad_slot_shown'));
    });

    test('reklam geçildikten sonra sonraki yuva 10. profilde', () async {
      final h = await _Harness.create();
      await h.reject(5);
      h.dismissAd();

      await h.reject(4);
      expect(h.ads.isShowing, isFalse);
      await h.reject(1);
      expect(h.ads.isShowing, isTrue);
      expect(h.ads.adsShown, 2);
    });

    test('oturum başına en çok 6 reklam', () async {
      final h = await _Harness.create(cards: 60);

      for (var i = 0; i < 50; i++) {
        await h.reject(1);
        if (h.ads.isShowing) h.dismissAd();
      }

      expect(h.ads.adsShown, 6);
      expect(h.admob.handles.length, lessThanOrEqualTo(7));
    });

    test('desteyi tüketen son profilden sonra reklam çıkmaz (kart yok)', () async {
      final h = await _Harness.create(cards: 5);

      await h.reject(5);

      expect(h.ids, isEmpty);
      expect(h.ads.isShowing, isFalse);
    });
  });

  group('deste izolasyonu — reklam kartı swipe/undo/seen ile ilişkisiz', () {
    test('reklam gösterme ve geçme swipe API\'sini çağırmaz, desteyi değiştirmez', () async {
      final h = await _Harness.create();
      await h.reject(5);
      final swipesBefore = List.of(h.repo.swipes);
      final idsBefore = h.ids;
      final lastBefore = h.deck.lastSwipedCard;

      expect(h.ads.isShowing, isTrue);
      h.dismissAd();
      await _settle();

      expect(h.repo.swipes, swipesBefore);
      expect(h.repo.swipes.every((s) => s.startsWith('REJECT:')), isTrue);
      expect(h.repo.swipes.length, 5);
      expect(h.ids, idsBefore);
      expect(h.deck.lastSwipedCard, lastBefore);
      expect(h.repo.undoCalls, 0);
    });

    test('undo yığınında reklam yok: son kart hâlâ son GERÇEK profil', () async {
      final h = await _Harness.create();
      await h.reject(5);
      h.dismissAd();

      expect(h.deck.lastSwipedCard?.userId, 'u4');
      expect(h.deck.canUndo, isTrue);

      await h.container.read(discoverProvider.notifier).undoSwipe();
      await _settle();

      expect(h.repo.undoCalls, 1);
      expect(h.ids.first, 'u4');
      // Undo bir profil GERİ getirir; geçilen profil sayacı reklam üretmez.
      expect(h.ads.isShowing, isFalse);
    });

    test('undo ile dönen kart geçiş sayılmaz (aynı profil iki kez sayılmaz)', () async {
      final h = await _Harness.create();
      await h.reject(3);
      await h.container.read(discoverProvider.notifier).undoSwipe();
      await _settle();

      expect(h.ads.profilesPassed, 3);
    });

    test('desteyi yeniden yükleme (filtre değişimi) geçiş sayılmaz', () async {
      final h = await _Harness.create();
      await h.reject(2);

      await h.container.read(discoverProvider.notifier).loadCards();
      await _settle();

      expect(h.ads.profilesPassed, 2);
    });
  });

  group('VIP / fail-closed / uzaktan kapalı — hiç istek yok', () {
    Future<void> expectNoAdActivity(_Harness h) async {
      await h.reject(25);
      expect(h.admob.readyCalls, 0, reason: 'SDK/consent başlatılmamalı');
      expect(h.admob.loadCalls, 0, reason: 'reklam isteği atılmamalı');
      expect(h.ads.isShowing, isFalse);
      expect(h.ads.adsShown, 0);
      expect(h.events, isEmpty);
    }

    test('VIP (Plus/Premium) kullanıcıya ne yüklenir ne gösterilir', () async {
      await expectNoAdActivity(await _Harness.create(audience: AdAudience.vip));
    });

    test('abonelik durumu bilinmiyorsa (yükleniyor/hata) reklam yok', () async {
      await expectNoAdActivity(await _Harness.create(audience: AdAudience.unknown));
    });

    test('uzaktan ads_enabled kapalıyken reklam yok', () async {
      await expectNoAdActivity(await _Harness.create(adsEnabled: false));
    });

    test('oturum ortasında VIP olunca yüklü reklam atılır, gösterilen reklam kapanır', () async {
      final h = await _Harness.create();
      await h.reject(5);
      expect(h.ads.isShowing, isTrue);

      h.container.read(_audienceSource.notifier).state = AdAudience.vip;
      await _settle();

      expect(h.ads.isShowing, isFalse);
      expect(h.admob.handles.every((x) => x.disposed), isTrue);

      final loadsAtVip = h.admob.loadCalls;
      await h.reject(12);
      expect(h.admob.loadCalls, loadsAtVip, reason: 'VIP olduktan sonra yeni istek yok');
      expect(h.ads.isShowing, isFalse);
    });
  });

  group('yükleme / onay / ATT', () {
    test('yükleme başarısız → yuva atlanır, deste akışı bozulmaz, sonraki yuva denenir', () async {
      final admob = FakeAdMob()..loadError = const NativeAdLoadException(3, 'no fill');
      final h = await _Harness.create(admob: admob);

      await h.reject(5);

      expect(h.ads.isShowing, isFalse);
      expect(h.ads.adsShown, 0);
      expect(h.ads.slotsResolved, 1);
      expect(h.events, contains('ad_failed'));
      expect(h.ids.length, 25); // 30 - 5: deste olduğu gibi akıyor

      admob.loadError = null;
      await h.reject(5);
      expect(h.ads.isShowing, isTrue);
      expect(h.ads.adsShown, 1);
    });

    test('UMP onayı yoksa reklam istenmez', () async {
      final admob = FakeAdMob()..consentGranted = false;
      final h = await _Harness.create(admob: admob);

      await h.reject(12);

      expect(admob.readyCalls, greaterThan(0));
      expect(admob.loadCalls, 0);
      expect(h.ads.isShowing, isFalse);
    });

    test('ATT izni yoksa kişiselleştirilmemiş (NPA) reklam istenir; izin varsa kişiselleştirilmiş', () async {
      final denied = await _Harness.create(attAuthorized: false);
      await denied.reject(3);
      expect(denied.admob.nonPersonalizedRequests, [true]);

      final granted = await _Harness.create(attAuthorized: true);
      await granted.reject(3);
      expect(granted.admob.nonPersonalizedRequests, [false]);
    });

    test('reklam geçilince tutamaç dispose edilir; provider kapanınca yüklü reklam da', () async {
      final h = await _Harness.create();
      await h.reject(5);
      final shown = h.admob.handles.single;

      h.dismissAd();
      expect(shown.disposed, isTrue);

      await h.reject(3); // sonraki yuva için önyükleme
      final preloaded = h.admob.handles.last;
      expect(preloaded.disposed, isFalse);
      h.container.dispose();
      expect(preloaded.disposed, isTrue);
    });
  });

  group('oturum değişimi (2.0.16 ConcurrentModificationError)', () {
    test('çıkışta (auth → unauthenticated) hata atılmaz, yüklü reklam tam 1 kez dispose edilir', () async {
      final h = await _Harness.create();
      await h.reject(3); // sonraki yuva için önyükleme → yüklü reklam var
      final preloaded = h.admob.handles.single;
      expect(h.ads.ad, same(preloaded));

      (h.container.read(authProvider.notifier) as _AuthedNotifier).signOut();
      await _settle();

      expect(() => h.container.read(discoverAdsProvider), returnsNormally);
      expect(preloaded.disposeCount, 1);
      expect(h.ads.ad, isNull, reason: 'yeni oturum boş başlar');
      expect(h.ads.profilesPassed, 0);

      h.container.dispose(); // eski reklam ikinci kez dispose edilmez
      expect(preloaded.disposeCount, 1);
    });

    test('çıkış sırasında yükleme sürüyorsa gelen reklam yeni oturuma sızmaz, dispose edilir', () async {
      final admob = _GatedAdMob();
      final h = await _Harness.create(admob: admob);
      await h.reject(3); // yükleme başladı, SDK cevabı bekleniyor
      expect(h.ads.isLoading, isTrue);

      (h.container.read(authProvider.notifier) as _AuthedNotifier).signOut();
      await _settle();
      admob.release();
      await _settle();

      final late = admob.handles.single;
      expect(late.disposeCount, 1);
      expect(h.ads.ad, isNull);
    });
  });
}

/// Yüklemeyi [release] çağrılana kadar bekletir (oturum değişimi yarışını kurmak için).
class _GatedAdMob extends FakeAdMob {
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<NativeAdHandle> loadNativeAd({
    required bool nonPersonalized,
    required NativeAdStyle style,
    VoidCallback? onImpression,
    VoidCallback? onClicked,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await _gate.future;
    return super.loadNativeAd(
      nonPersonalized: nonPersonalized,
      style: style,
      onImpression: onImpression,
      onClicked: onClicked,
      timeout: timeout,
    );
  }
}
