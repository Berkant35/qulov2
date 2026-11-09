import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/repositories/city_repository.dart';
import 'package:qulo_v2/data/repositories/match_repository.dart';
import 'package:qulo_v2/features/location/providers/city_picker_provider.dart';
import 'package:qulo_v2/features/location/providers/city_picker_state.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';

import '../../../helpers/fake_repositories.dart';

/// Konumsuz yedek yol (2.0.18 madde 9): kayıtların %19'u (yeni kadınların %30'u)
/// konum vermediği için kart göremiyordu. Şehir seçilince sunucu şehir merkezini
/// konum olarak yazar; istemci profili ve desteyi yeniden çeker.
const _istanbul = CityModel(id: 'TR-istanbul', name: 'İstanbul', country: 'TR');
const _roma = CityModel(id: 'IT-rome', name: 'Roma', country: 'IT');

class _FakeCities implements CityRepository {
  final searches = <({String? country, String query})>[];
  final saved = <String>[];
  Result<void> saveResult = const Success(null);
  Completer<void>? searchGate;
  List<String> countries = ['TR', 'IT'];

  @override
  Future<Result<CityListResponse>> search({String? country, String query = '', int limit = 100}) async {
    searches.add((country: country, query: query));
    await searchGate?.future;
    final cities = switch (country) {
      'TR' => [_istanbul],
      'IT' => [_roma],
      _ => <CityModel>[],
    };
    return Success(CityListResponse(countries: countries, cities: cities));
  }

  @override
  Future<Result<void>> setCity(String cityId) async {
    saved.add(cityId);
    return saveResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('_FakeCities.${invocation.memberName}');
}

class _CountingMatch implements MatchRepository {
  int discoverCalls = 0;

  @override
  Future<Result<DiscoverResponse>> discover({int page = 1}) async {
    discoverCalls++;
    return const Success(DiscoverResponse(cards: [], page: 1, hasMore: false));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('_CountingMatch.${invocation.memberName}');
}

class _Rig {
  _Rig({String? region = 'TR'}) {
    container = ProviderContainer(overrides: [
      deviceRegionProvider.overrideWithValue(region),
      cityRepositoryProvider.overrideWithValue(cities),
      userRepositoryProvider.overrideWithValue(users),
      matchRepositoryProvider.overrideWithValue(match),
    ]);
    addTearDown(container.dispose);
    container.listen(cityPickerProvider, (_, __) {}); // ekran açık
  }

  final cities = _FakeCities();
  final match = _CountingMatch();
  // Sunucu şehir merkezini profile yazmış hâli (PATCH sonrası getMe).
  final users = FakeUserRepository(UserModel(
    id: 'u1',
    email: 'u1@qulo.test',
    lat: 41.01,
    lng: 28.97,
    city: 'İstanbul',
    genderPrefSetAt: DateTime.utc(2026, 11, 1),
  ));
  late final ProviderContainer container;

  CityPickerNotifier get notifier => container.read(cityPickerProvider.notifier);
  CityPickerState get state => container.read(cityPickerProvider);
}

void main() {
  group('açılış: ülke varsayılanı cihaz bölgesi', () {
    test('bölge destekleniyorsa o ülkenin şehirleri, ipucu yok', () async {
      final r = _Rig(region: 'TR');

      await r.notifier.start();

      expect(r.cities.searches.single.country, 'TR');
      expect(r.state.cities, [_istanbul]);
      expect(r.state.countries, ['TR', 'IT']);
      expect(r.state.regionUnsupported, isFalse);
    });

    test('bölge listede yoksa en çok kullanıcılı ülkeye düşer, "en yakın büyük şehir" ipucu', () async {
      final r = _Rig(region: 'DE')..cities.countries = ['IT', 'TR'];

      await r.notifier.start();

      expect(r.cities.searches.map((s) => s.country), ['DE', 'IT']);
      expect(r.state.country, 'IT');
      expect(r.state.cities, [_roma]);
      expect(r.state.regionUnsupported, isTrue);
    });

    test('cihaz bölgesi bilinmiyorsa (null) da ilk ülkeye düşer', () async {
      final r = _Rig(region: null);

      await r.notifier.start();

      expect(r.state.country, 'TR');
      expect(r.state.regionUnsupported, isTrue);
    });
  });

  test('ülke değişince arama metni korunur', () async {
    final r = _Rig();
    await r.notifier.start();
    await r.notifier.search('ro');

    await r.notifier.selectCountry('IT');

    expect(r.cities.searches.last, (country: 'IT', query: 'ro'));
  });

  test('geç dönen eski arama yeni sonucu ezmez', () async {
    final r = _Rig();
    await r.notifier.start();
    final gate = Completer<void>();
    r.cities.searchGate = gate;

    final slow = r.notifier.selectCountry('IT');
    r.cities.searchGate = null;
    await r.notifier.selectCountry('TR');
    gate.complete();
    await slow;

    expect(r.state.country, 'TR');
    expect(r.state.cities, [_istanbul]);
  });

  group('kaydetme', () {
    test('başarı: profil yeniden çekilir, şehir merkezi konum olur, deste yüklenir', () async {
      final r = _Rig();
      await r.notifier.start();

      final result = await r.notifier.save(_istanbul);

      expect(result, CitySaveResult.saved);
      expect(r.cities.saved, ['TR-istanbul']);
      expect(r.users.getMeCallCount, 1);
      final location = r.container.read(locationProvider);
      expect((location.lat, location.lng), (41.01, 28.97));
      expect(r.match.discoverCalls, greaterThanOrEqualTo(1));
    });

    test('404 CITY_NOT_FOUND: liste tazelenir, konuma / desteye dokunulmaz', () async {
      final r = _Rig();
      await r.notifier.start();
      r.cities.saveResult = const Failure(ServerFailure(code: 'CITY_NOT_FOUND', statusCode: 404));

      final result = await r.notifier.save(_istanbul);

      expect(result, CitySaveResult.cityGone);
      expect(r.cities.searches, hasLength(2));
      expect(r.users.getMeCallCount, 0);
      expect(r.match.discoverCalls, 0);
      expect(r.state.savingCityId, isNull, reason: 'kullanıcı yeniden seçebilmeli');
    });

    test('ağ hatası: failed, liste tazelenmez', () async {
      final r = _Rig();
      await r.notifier.start();
      r.cities.saveResult = const Failure(NetworkFailure());

      expect(await r.notifier.save(_istanbul), CitySaveResult.failed);
      expect(r.cities.searches, hasLength(1));
      expect(r.state.savingCityId, isNull);
    });

    test('kayıt sürerken ikinci dokunuş yok sayılır', () async {
      final r = _Rig();
      await r.notifier.start();

      final first = r.notifier.save(_istanbul);
      final second = await r.notifier.save(_istanbul);
      await first;

      expect(second, isNull);
      expect(r.cities.saved, ['TR-istanbul']);
    });
  });
}
