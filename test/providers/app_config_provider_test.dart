import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/app_info_manager.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';
import 'package:qulo_v2/data/repositories/app_config_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Acilista ve her resume'da (`VersionManager`) calisan surum kapisi.
///
/// Oncelik: bakim > zorunlu > opsiyonel > yok. Hata durumunda kapi ACIK kalir
/// (fail-open): config alinamazsa kullanici kilitlenmez.
class _FakeAppInfo implements AppInfoManager {
  _FakeAppInfo(this._version, {this.error});

  final String _version;
  final Object? error;

  @override
  Future<String> get version async {
    if (error != null) throw error!;
    return _version;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAppInfo.${invocation.memberName}');
}

class _FakeAppConfigRepository implements AppConfigRepository {
  _FakeAppConfigRepository(this.result);

  final Result<AppConfigModel> result;

  @override
  Future<Result<AppConfigModel>> getConfig() async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAppConfigRepository.${invocation.memberName}');
}

AppConfigModel _config({
  String min = '2.0.0',
  String latest = '2.0.0',
  bool maintenance = false,
  bool force = true,
}) =>
    AppConfigModel(
      minVersion: min,
      latestVersion: latest,
      storeUrl: 'https://store.example/qulo',
      isMaintenance: maintenance,
      isForceUpdateEnabled: force,
    );

ProviderContainer _container(
  String current,
  Result<AppConfigModel> result, {
  Object? versionError,
}) {
  final container = ProviderContainer(overrides: [
    appInfoManagerProvider.overrideWithValue(_FakeAppInfo(current, error: versionError)),
    appConfigRepositoryProvider.overrideWithValue(_FakeAppConfigRepository(result)),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<UpdateStatus> _check(String current, AppConfigModel config) =>
    _container(current, Success(config)).read(appConfigProvider.notifier).checkVersion();

void main() {
  group('checkVersion — durum onceligi', () {
    test('bakim modu her seyin onunde — zorunlu guncelleme gerekse bile', () async {
      final status = await _check(
        '2.0.0',
        _config(min: '2.0.10', latest: '2.0.10', maintenance: true),
      );

      expect(status, UpdateStatus.maintenance);
    });

    test('min altinda ve zorunlu acik → forceUpdate', () async {
      final status = await _check('2.0.9', _config(min: '2.0.10', latest: '2.0.10'));

      expect(status, UpdateStatus.forceUpdate);
    });

    test('zorunlu KAPALIYKEN min altindaki kullanici engellenmez, opsiyonel gorur', () async {
      final status = await _check(
        '2.0.9',
        _config(min: '2.0.10', latest: '2.0.10', force: false),
      );

      expect(status, UpdateStatus.optionalUpdate);
    });

    test('min ustu, latest alti → optionalUpdate', () async {
      final status = await _check('2.0.10', _config(min: '2.0.9', latest: '2.0.11'));

      expect(status, UpdateStatus.optionalUpdate);
    });

    test('iki haneli parca: 2.0.10, min 2.0.9 icin zorunlu SAYILMAZ', () async {
      final status = await _check('2.0.10', _config(min: '2.0.9', latest: '2.0.10'));

      expect(status, UpdateStatus.none);
    });

    test('latest ustu (henuz yayinlanmamis TestFlight surumu) → none', () async {
      final status = await _check('2.0.11', _config(min: '2.0.9', latest: '2.0.10'));

      expect(status, UpdateStatus.none);
    });

    test('basarida config, durum ve mevcut surum state\'e yazilir', () async {
      final container = _container('2.0.9', Success(_config(min: '2.0.10', latest: '2.0.10')));

      await container.read(appConfigProvider.notifier).checkVersion();

      final state = container.read(appConfigProvider);
      expect(state.status, UpdateStatus.forceUpdate);
      expect(state.currentVersion, '2.0.9');
      expect(state.config?.storeUrl, 'https://store.example/qulo');
      expect(state.isLoading, isFalse);
    });
  });

  group('checkVersion — fail-open', () {
    test('config alinamazsa none — uygulama acilir, kilitlenmez', () async {
      final container = _container('2.0.0', const Failure(NetworkFailure()));

      final status = await container.read(appConfigProvider.notifier).checkVersion();

      expect(status, UpdateStatus.none);
      expect(container.read(appConfigProvider).isLoading, isFalse);
    });

    test('surum okunamazsa none', () async {
      final container = _container(
        '2.0.0',
        Success(_config(min: '9.9.9', latest: '9.9.9')),
        versionError: Exception('package_info yok'),
      );

      final status = await container.read(appConfigProvider.notifier).checkVersion();

      expect(status, UpdateStatus.none);
      expect(container.read(appConfigProvider).isLoading, isFalse);
    });

    test('sozlesme disi surum bicimi (build numarali) none\'a duser', () async {
      // Zorunlu guncelleme gerekirken bile: karsilastirma FormatException
      // atar, notifier yakalar. Bu yuzden istemci `version` (build'siz)
      // gondermek ZORUNDA — `headerVersion` degil.
      final status = await _check('2.0.9+72', _config(min: '2.0.10', latest: '2.0.10'));

      expect(status, UpdateStatus.none);
    });
  });

  group('opsiyonel guncelleme erteleme — 24 saat', () {
    const key = 'optional_update_dismissed_at';

    AppConfigNotifier notifier() =>
        _container('2.0.0', Success(_config())).read(appConfigProvider.notifier);

    int hoursAgo(int h) =>
        DateTime.now().subtract(Duration(hours: h)).millisecondsSinceEpoch;

    test('hic ertelenmediyse false', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await notifier().isOptionalUpdateDismissed(), isFalse);
    });

    test('23 saat once ertelendiyse hala ertelenmis', () async {
      SharedPreferences.setMockInitialValues({key: hoursAgo(23)});

      expect(await notifier().isOptionalUpdateDismissed(), isTrue);
    });

    test('25 saat once ertelendiyse tekrar gosterilir', () async {
      SharedPreferences.setMockInitialValues({key: hoursAgo(25)});

      expect(await notifier().isOptionalUpdateDismissed(), isFalse);
    });

    test('dismissOptionalUpdate sonrasi ertelenmis sayilir', () async {
      SharedPreferences.setMockInitialValues({});
      final n = notifier();

      await n.dismissOptionalUpdate();

      expect(await n.isOptionalUpdateDismissed(), isTrue);
    });
  });
}
