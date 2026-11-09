import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Cinsiyet tercihi ayarlanmadan discover çekilmez (sunucu 14a1f0a
/// PROFILE_INCOMPLETE döner); adayı eleyen bir tercih (cinsiyet, dil, yaş —
/// `discover_filter_key.dart`) ayarlanınca/değişince deste yenilenir.
///
/// Kök neden (3 Eki): giriş ön-yüklemesi (`auth_provider` → `loadCards`)
/// tercih seçilmeden çalışıyordu; WOMAN tercihli erkeklere erkek profiller
/// gidiyordu ve 400'ler Crashlytics'e non-fatal düşüyordu.
void main() {
  final noPref = UserModel(id: 'u1', email: 'u1@qulo.test');
  final women = UserModel(
    id: 'u1',
    email: 'u1@qulo.test',
    genderPref: 'WOMAN',
    genderPrefSetAt: DateTime(2026, 10, 3),
  );
  final men = UserModel(
    id: 'u1',
    email: 'u1@qulo.test',
    genderPref: 'MAN',
    genderPrefSetAt: DateTime(2026, 10, 3),
  );

  final declined = UserModel(id: 'u1', email: 'u1@qulo.test', prefConsentStatus: PrefConsent.declined);

  test('tercih yoksa loadCards istek atmaz, deste başlatılmamış kalır', () async {
    final h = await _Harness.create(user: noPref);

    await h.notifier.loadCards();

    expect(h.repo.discoverCalls, 0);
    expect(h.state.initialized, isFalse);
  });

  test('tercih varsa loadCards yükler', () async {
    final h = await _Harness.create(user: women);

    await h.notifier.loadCards();

    expect(h.repo.discoverCalls, 1);
    expect(h.state.initialized, isTrue);
  });

  test('kullanıcı henüz yüklenmediyse istek engellenmez (sunucu karar verir)', () async {
    final h = await _Harness.create(user: null);

    await h.notifier.loadCards();

    expect(h.repo.discoverCalls, 1);
  });

  test('tercih ilk kez ayarlanınca (setup gate) deste yüklenir', () async {
    final h = await _Harness.create(user: noPref, withLocation: true);
    await h.notifier.loadCards();
    expect(h.repo.discoverCalls, 0);

    h.emitUser(women);
    await _settle();

    expect(h.repo.discoverCalls, 1);
    expect(h.state.initialized, isTrue);
  });

  test('tercih değişince deste yenilenir', () async {
    final h = await _Harness.create(user: women, withLocation: true);
    await h.notifier.loadCards();

    h.emitUser(men);
    await _settle();

    expect(h.repo.discoverCalls, 2);
  });

  test('aynı tercihle kullanıcı tazelenmesi (fetchMe) yeniden yüklemez', () async {
    final h = await _Harness.create(user: women, withLocation: true);
    await h.notifier.loadCards();

    h.emitUser(UserModel(
      id: 'u1',
      email: 'u1@qulo.test',
      bio: 'yeni bio',
      genderPref: 'WOMAN',
      genderPrefSetAt: DateTime(2026, 10, 3),
    ));
    await _settle();

    expect(h.repo.discoverCalls, 1);
  });

  test('konum yoksa tercih ayarlansa da istek atılmaz (konumsuz → PROFILE_INCOMPLETE)', () async {
    final h = await _Harness.create(user: noPref);

    h.emitUser(women);
    await _settle();

    expect(h.repo.discoverCalls, 0);
  });

  test('kullanıcı verisinin ilk gelişi (null → değer) yükleme tetiklemez', () async {
    final h = await _Harness.create(user: null, withLocation: true);

    h.emitUser(women);
    await _settle();

    expect(h.repo.discoverCalls, 0, reason: 'ilk yüklemeyi giriş akışı yapar');
  });

  test('rıza reddedilmiş kullanıcı ("Herkes" modu) için loadCards istek atar', () async {
    final h = await _Harness.create(user: declined);
    await h.notifier.loadCards();
    expect(h.repo.discoverCalls, 1);
  });

  test('rıza geri alınınca (WOMAN → DECLINED) deste yenilenir', () async {
    final h = await _Harness.create(user: women, withLocation: true);
    await h.notifier.loadCards();
    h.emitUser(declined);
    await _settle();
    expect(h.repo.discoverCalls, 2);
  });

  // Kök neden (11 Eki): boş Discover'ın "Dil tercihlerini düzenle" butonu profil
  // düzenlemeyi açıyordu; kayıttan dönünce Discover ekranı canlı kaldığı için
  // deste yeniden çekilmiyor, eski boş durum ekranda kalıyordu. Dil ve yaş
  // aralığı da cinsiyet gibi sunucuda adayı ELEYEN filtreler.
  group('eleyen filtre tercihleri', () {
    UserModel withPrefs({
      List<String> languages = const ['tr'],
      int? ageMin = 25,
      int? ageMax = 35,
      int radiusKm = 50,
    }) =>
        UserModel(
          id: 'u1',
          email: 'u1@qulo.test',
          genderPref: 'WOMAN',
          genderPrefSetAt: DateTime(2026, 10, 3),
          preferredLanguages: languages,
          agePrefMin: ageMin,
          agePrefMax: ageMax,
          matchRadiusKm: radiusKm,
        );

    Future<int> callsAfterChange(UserModel before, UserModel after) async {
      final h = await _Harness.create(user: before, withLocation: true);
      await h.notifier.loadCards();
      h.emitUser(after);
      await _settle();
      return h.repo.discoverCalls;
    }

    test('dil listesi değişince deste yenilenir', () async {
      expect(await callsAfterChange(withPrefs(), withPrefs(languages: ['tr', 'en'])), 2);
    });

    test('boş dil durumu: dil eklenince eski boş deste yerine kartlar gelir (bildirilen belirti)',
        () async {
      final h = await _Harness.create(user: withPrefs(), withLocation: true);
      h.repo.queued.add(const DiscoverResponse(
        cards: [],
        page: 1,
        hasMore: false,
        emptyReason: 'language',
      ));
      await h.notifier.loadCards();
      expect(h.state.emptyReason, 'language');

      h.emitUser(withPrefs(languages: ['tr', 'en']));
      await _settle();

      expect(h.state.cards, isNotEmpty);
      expect(h.state.emptyReason, isNull);
    });

    test('yaş aralığı değişince deste yenilenir', () async {
      expect(await callsAfterChange(withPrefs(), withPrefs(ageMax: 45)), 2);
    });

    test('aynı diller farklı sırayla gelince yeniden yüklemez', () async {
      expect(
        await callsAfterChange(withPrefs(languages: ['tr', 'en']), withPrefs(languages: ['en', 'tr'])),
        1,
      );
    });

    test('yalnız yarıçap değişince yeniden yüklemez (sert filtre değil; "tekrar ara" kendi çeker)',
        () async {
      expect(await callsAfterChange(withPrefs(), withPrefs(radiusKm: 120)), 1);
    });
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness._(this.repo, UserModel? user) {
    container = ProviderContainer(overrides: [
      matchRepositoryProvider.overrideWithValue(repo),
      userProvider.overrideWith(() => _MutableUserNotifier(user)),
    ]);
    addTearDown(container.dispose);
  }

  static Future<_Harness> create({
    required UserModel? user,
    bool withLocation = false,
  }) async {
    final h = _Harness._(_FakeMatchRepository(), user);
    await h.container.read(userProvider.future);
    if (withLocation) {
      h.container.read(locationProvider.notifier).seedFromProfile(lat: 41, lng: 29);
    }
    await h.container.read(discoverProvider.future);
    return h;
  }

  final _FakeMatchRepository repo;
  late final ProviderContainer container;

  DiscoverNotifier get notifier => container.read(discoverProvider.notifier);
  DiscoverState get state => container.read(discoverProvider).requireValue;

  void emitUser(UserModel? user) =>
      (container.read(userProvider.notifier) as _MutableUserNotifier).emit(user);
}

class _MutableUserNotifier extends UserNotifier {
  _MutableUserNotifier(this._initial);

  final UserModel? _initial;

  @override
  Future<UserModel?> build() async => _initial;

  void emit(UserModel? user) => state = AsyncData(user);
}

class _FakeMatchRepository implements MatchRepository {
  int discoverCalls = 0;

  /// Sıradaki yanıtlar; boşsa varsayılan 5 kartlık deste.
  final queued = <DiscoverResponse>[];

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    discoverCalls++;
    if (queued.isNotEmpty) return Success(queued.removeAt(0));
    return Success(DiscoverResponse(
      cards: [
        for (final id in ['a', 'b', 'c', 'd', 'e'])
          ProfileCardModel(userId: id, questionCount: 2, distanceKm: 10, distanceTier: 0),
      ],
      page: 1,
      hasMore: true,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeMatchRepository.${invocation.memberName}');
}
