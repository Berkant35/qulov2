import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';

/// Konum — discover konumsuz calismaz (radius filtresi). Hata kodlari ekranda
/// ayri varyantlara donusur (servis kapali / izin reddi / kalici red / sahte konum).
/// Izin eslemesi (`_mapPermission`) Geolocator'a bagli; burada fake manager var.
void main() {
  group('getCurrentLocation — izin akisi', () {
    test('izin varken konum ve sehir yazilir, sunucuya gonderilir', () async {
      final h = _Harness();

      await h.notifier.getCurrentLocation();

      expect(h.state.lat, 41.0);
      expect(h.state.lng, 29.0);
      expect(h.state.city, 'Istanbul');
      expect(h.state.isLoading, isFalse);
      expect(h.state.error, isNull);
      expect(h.users.sent, (41.0, 29.0, 'Istanbul'));
      expect(h.location.requestCalls, 0);
    });

    test('konum servisi kapaliysa izin istenmez', () async {
      final h = _Harness()..location.serviceEnabled = false;

      await h.notifier.getCurrentLocation();

      expect(h.state.error, 'LOCATION_SERVICE_DISABLED');
      expect(h.location.checkCalls, 0);
      expect(h.location.positionCalls, 0);
    });

    test('izin yoksa istenir; verilirse konum alinir', () async {
      final h = _Harness()
        ..location.checkResult = LocationPermissionStatus.denied
        ..location.requestResult = LocationPermissionStatus.granted;

      await h.notifier.getCurrentLocation();

      expect(h.location.requestCalls, 1);
      expect(h.state.lat, 41.0);
    });

    test('istenen izin reddedilirse LOCATION_PERMISSION_DENIED, konum alinmaz', () async {
      final h = _Harness()
        ..location.checkResult = LocationPermissionStatus.denied
        ..location.requestResult = LocationPermissionStatus.denied;

      await h.notifier.getCurrentLocation();

      expect(h.state.error, 'LOCATION_PERMISSION_DENIED');
      expect(h.location.positionCalls, 0);
    });

    test('kalici red: tekrar sorulmaz (sistem gostermez), ayarlara yonlendirme kodu', () async {
      final h = _Harness()..location.checkResult = LocationPermissionStatus.deniedForever;

      await h.notifier.getCurrentLocation();

      expect(h.state.error, 'LOCATION_PERMISSION_DENIED_FOREVER');
      expect(h.location.requestCalls, 0);
    });

    test('istek sonrasi kalici red (Android "bir daha sorma") ayni koda duser', () async {
      final h = _Harness()
        ..location.checkResult = LocationPermissionStatus.denied
        ..location.requestResult = LocationPermissionStatus.deniedForever;

      await h.notifier.getCurrentLocation();

      expect(h.state.error, 'LOCATION_PERMISSION_DENIED_FOREVER');
      expect(h.location.positionCalls, 0);
    });

    test('sahte konum LOCATION_MOCK_DETECTED', () async {
      final h = _Harness()..location.positionError = const MockLocationException();

      await h.notifier.getCurrentLocation();

      expect(h.state.error, 'LOCATION_MOCK_DETECTED');
      expect(h.users.sent, isNull);
    });
  });

  group('getCurrentLocation — veri korunumu', () {
    for (final city in <String?>[null, '']) {
      test('sehir bulunamazsa ("$city") onceki sehir korunur', () async {
        final h = _Harness()..notifier.seedFromProfile(lat: 40.0, lng: 28.0, city: 'Bursa');
        h.location.position = LocationResult(lat: 41.0, lng: 29.0, city: city);

        await h.notifier.getCurrentLocation();

        expect(h.state.lat, 41.0);
        expect(h.state.city, 'Bursa');
      });
    }

    test('sunucu guncellemesi basarisiz olsa da yerel konum korunur', () async {
      final h = _Harness()..users.result = const Failure(UnauthorizedFailure());

      await h.notifier.getCurrentLocation();

      expect(h.state.lat, 41.0);
      expect(h.state.error, isNull);
    });

    test('sunucu guncellemesi firlatirsa da yerel konum korunur', () async {
      final h = _Harness()..users.throwOnUpdate = true;

      await h.notifier.getCurrentLocation();

      expect(h.state.lat, 41.0);
      expect(h.state.error, isNull);
    });

    test('hata durumunda bilinen konum silinmez', () async {
      final h = _Harness()..notifier.seedFromProfile(lat: 40.0, lng: 28.0, city: 'Bursa');
      h.location.serviceEnabled = false;

      await h.notifier.getCurrentLocation();

      expect(h.state.error, 'LOCATION_SERVICE_DISABLED');
      expect(h.state.lat, 40.0);
      expect(h.state.city, 'Bursa');
    });
  });

  group('onAppResumed', () {
    test('ilk resume konumu gunceller', () async {
      final h = _Harness();

      h.notifier.onAppResumed();
      await _settle();

      expect(h.location.positionCalls, 1);
    });

    test('basaridan hemen sonra (15 dk dolmadan) tekrar denemez', () async {
      final h = _Harness();
      await h.notifier.getCurrentLocation();

      h.notifier.onAppResumed();
      await _settle();

      expect(h.location.positionCalls, 1);
    });

    test('hata varsa her resume\'da tekrar dener — ayarlardan izin verip donen kullanici', () async {
      final h = _Harness()..location.checkResult = LocationPermissionStatus.deniedForever;
      await h.notifier.getCurrentLocation();
      h.location.checkResult = LocationPermissionStatus.granted;

      h.notifier.onAppResumed();
      await _settle();

      expect(h.state.error, isNull);
      expect(h.state.lat, 41.0);
    });

    test('yukleme surerken tetiklenmez', () async {
      final gate = Completer<LocationResult>();
      final h = _Harness()..location.positionGate = gate;
      unawaited(h.notifier.getCurrentLocation());
      await _settle();

      h.notifier.onAppResumed();
      await _settle();
      gate.complete(const LocationResult(lat: 41.0, lng: 29.0));
      await _settle();

      expect(h.location.positionCalls, 1);
    });
  });

  group('seedFromProfile', () {
    test('bosken profildeki konumla doldurur — GPS beklemeden discover calisir', () {
      final h = _Harness();

      h.notifier.seedFromProfile(lat: 40.0, lng: 28.0, city: 'Bursa');

      expect(h.state.lat, 40.0);
      expect(h.state.city, 'Bursa');
    });

    test('GPS konumu varken profil konumu uzerine yazmaz', () async {
      final h = _Harness();
      await h.notifier.getCurrentLocation();

      h.notifier.seedFromProfile(lat: 40.0, lng: 28.0, city: 'Bursa');

      expect(h.state.lat, 41.0);
      expect(h.state.city, 'Istanbul');
    });
  });
}

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(overrides: [
      locationManagerProvider.overrideWithValue(location),
      userRepositoryProvider.overrideWithValue(users),
    ]);
    addTearDown(container.dispose);
  }

  final location = _FakeLocationManager();
  final users = _FakeUserRepository();
  late final ProviderContainer container;

  LocationNotifier get notifier => container.read(locationProvider.notifier);
  LocationState get state => container.read(locationProvider);
}

class _FakeLocationManager implements LocationManager {
  bool serviceEnabled = true;
  LocationPermissionStatus checkResult = LocationPermissionStatus.granted;
  LocationPermissionStatus requestResult = LocationPermissionStatus.granted;
  LocationResult position = const LocationResult(lat: 41.0, lng: 29.0, city: 'Istanbul');
  Object? positionError;
  Completer<LocationResult>? positionGate;

  int checkCalls = 0;
  int requestCalls = 0;
  int positionCalls = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    checkCalls++;
    return checkResult;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<LocationResult> getCurrentPosition() async {
    positionCalls++;
    if (positionError != null) throw positionError!;
    if (positionGate != null) return positionGate!.future;
    return position;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeLocationManager.${invocation.memberName}');
}

class _FakeUserRepository implements UserRepository {
  Result<void> result = const Success(null);
  bool throwOnUpdate = false;
  (double, double, String?)? sent;

  @override
  Future<Result<void>> updateLocation({required double lat, required double lng, String? city}) async {
    if (throwOnUpdate) throw Exception('beklenmeyen');
    sent = (lat, lng, city);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeUserRepository.${invocation.memberName}');
}
