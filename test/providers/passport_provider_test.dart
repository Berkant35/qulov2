import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/repositories/passport_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';

/// Pasaport (Premium) — baska sehirden discover. Sehir degistirme sunucuda
/// iki adim: once kapat, sonra yeni sehirle ac; acma basarisizsa onceki sehir
/// geri acilmaya calisilir. Hata kullaniciya `Result` ile gosteriliyor
/// (`map_confirm_screen_mixin`), state.failure ile degil.
void main() {
  group('ac / kapat', () {
    test('acma basarili — sehir ve konum yazilir', () async {
      final h = _Harness();

      await h.notifier.activate(city: 'Paris', lat: 48.85, lng: 2.35);

      expect(h.state.isActive, isTrue);
      expect((h.state.city, h.state.lat, h.state.lng), ('Paris', 48.85, 2.35));
      expect(h.state.isLoading, isFalse);
      expect(h.repo.calls, ['activate:Paris']);
    });

    test('acma hatasi (Premium degil) — pasif kalir, hata tasinir', () async {
      final h = _Harness()..repo.activateResults.add(_premiumRequired);

      final result = await h.notifier.activate(city: 'Paris', lat: 48.85, lng: 2.35);

      expect(result.isFailure, isTrue);
      expect(h.state.isActive, isFalse);
      expect((h.state.failure as ServerFailure).code, 'PREMIUM_REQUIRED');
      expect(h.state.isLoading, isFalse);
    });

    test('kapatma basarili — pasif ve sehirsiz', () async {
      final h = _Harness()..notifier.syncFromUser('Paris', 48.85, 2.35);

      await h.notifier.deactivate();

      expect(h.state.isActive, isFalse);
      expect(h.state.city, isNull);
    });

    test('kapatma hatasi — aktif kalir, hata tasinir', () async {
      final h = _Harness()..notifier.syncFromUser('Paris', 48.85, 2.35);
      h.repo.deactivateResult = const Failure(NetworkFailure());

      await h.notifier.deactivate();

      expect(h.state.isActive, isTrue);
      expect(h.state.city, 'Paris');
      expect(h.state.failure, isA<NetworkFailure>());
    });
  });

  group('sehir degistirme', () {
    test('once kapatilir, sonra yeni sehir acilir', () async {
      final h = _Harness()..notifier.syncFromUser('Paris', 48.85, 2.35);

      final result = await h.notifier.changeCity(city: 'Roma', lat: 41.9, lng: 12.5);

      expect(result.isSuccess, isTrue);
      expect(h.repo.calls, ['deactivate', 'activate:Roma']);
      expect(h.state.city, 'Roma');
      expect(h.state.isActive, isTrue);
    });

    test('kapatma basarisizsa yeni sehir ACILMAZ, eski sehir kalir', () async {
      final h = _Harness()..notifier.syncFromUser('Paris', 48.85, 2.35);
      h.repo.deactivateResult = const Failure(NetworkFailure());

      final result = await h.notifier.changeCity(city: 'Roma', lat: 41.9, lng: 12.5);

      expect(result.isFailure, isTrue);
      expect(h.repo.calls, ['deactivate']);
      expect(h.state.city, 'Paris');
      expect(h.state.isLoading, isFalse);
    });

    test('yeni sehir acilamazsa onceki sehir geri acilir', () async {
      final h = _Harness()..notifier.syncFromUser('Paris', 48.85, 2.35);
      h.repo.activateResults.add(_premiumRequired);

      final result = await h.notifier.changeCity(city: 'Roma', lat: 41.9, lng: 12.5);
      await _settle();

      expect(result.isFailure, isTrue, reason: 'kullanici hatayi Result ile gorur');
      expect(h.repo.calls, ['deactivate', 'activate:Roma', 'activate:Paris']);
      expect(h.state.city, 'Paris');
      expect(h.state.isActive, isTrue);
      expect(h.state.isLoading, isFalse);
    });

    test('geri acma da basarisizsa pasif — sunucuda da pasaport kalmadi', () async {
      final h = _Harness()..notifier.syncFromUser('Paris', 48.85, 2.35);
      h.repo.activateResults.addAll([_premiumRequired, const Failure(NetworkFailure())]);

      await h.notifier.changeCity(city: 'Roma', lat: 41.9, lng: 12.5);
      await _settle();

      expect(h.state.isActive, isFalse);
      expect(h.state.city, isNull);
    });

    test('onceki sehir yokken acilamazsa hata tasinir, geri acma denenmez', () async {
      final h = _Harness()..repo.activateResults.add(_premiumRequired);

      await h.notifier.changeCity(city: 'Roma', lat: 41.9, lng: 12.5);
      await _settle();

      expect(h.repo.calls, ['deactivate', 'activate:Roma']);
      expect((h.state.failure as ServerFailure).code, 'PREMIUM_REQUIRED');
      expect(h.state.isLoading, isFalse);
    });
  });

  group('syncFromUser', () {
    test('profilde pasaport sehri varsa aktif gosterilir', () {
      final h = _Harness();

      h.notifier.syncFromUser('Paris', 48.85, 2.35);

      expect(h.state.isActive, isTrue);
      expect(h.state.city, 'Paris');
    });

    test('sehir yoksa durum degismez (giriste taze provider — pasif kalir)', () {
      final h = _Harness();

      h.notifier.syncFromUser(null, null, null);

      expect(h.state.isActive, isFalse);
    });
  });
}

const _premiumRequired = Failure<Map<String, dynamic>>(ServerFailure(code: 'PREMIUM_REQUIRED', statusCode: 403));

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(overrides: [passportRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
  }

  final repo = _FakePassportRepository();
  late final ProviderContainer container;

  PassportNotifier get notifier => container.read(passportProvider.notifier);
  PassportState get state => container.read(passportProvider);
}

class _FakePassportRepository implements PassportRepository {
  final calls = <String>[];
  final activateResults = <Result<Map<String, dynamic>>>[];
  Result<void> deactivateResult = const Success(null);

  @override
  Future<Result<Map<String, dynamic>>> activate({
    required String city,
    required double lat,
    required double lng,
  }) async {
    calls.add('activate:$city');
    return activateResults.isEmpty
        ? const Success(<String, dynamic>{'ok': true})
        : activateResults.removeAt(0);
  }

  @override
  Future<Result<void>> deactivate() async {
    calls.add('deactivate');
    return deactivateResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakePassportRepository.${invocation.memberName}');
}
