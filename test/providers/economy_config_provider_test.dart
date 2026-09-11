import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';
import 'package:qulo_v2/data/repositories/app_config_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ekonomi config'i — splash'te cekilir; guc/elmas fiyatlari buradan.
/// Hata: once onbellek, yoksa derlenmis varsayilan; 30 sn sonra arka planda
/// bir kez daha denenir.
void main() {
  test('basarida sunucu config\'i yazilir', () async {
    SharedPreferences.setMockInitialValues({});
    final h = _Harness([Success(_response(boost: 77))]);

    await h.fetch();

    expect(h.state.core.boostCostGreen, 77);
  });

  test('ag hatasinda ONCEKI acilisin config\'i kullanilir — cevrimdisi fiyat dogru', () async {
    SharedPreferences.setMockInitialValues({});
    await _Harness([Success(_response(boost: 77))]).fetch();

    final offline = _Harness([const Failure(NetworkFailure())]);
    await offline.fetch();

    expect(offline.state.core.boostCostGreen, 77);
  });

  test('onbellek yoksa derlenmis varsayilanlar kalir', () async {
    SharedPreferences.setMockInitialValues({});
    final h = _Harness([const Failure(NetworkFailure())]);

    await h.fetch();

    expect(h.state, EconomyConfig.fallback);
  });

  test('bozuk onbellek cokmez — varsayilanlar kalir', () async {
    SharedPreferences.setMockInitialValues({'economy_config_cache': '{bozuk json'});
    final h = _Harness([const Failure(NetworkFailure())]);

    await h.fetch();

    expect(h.state, EconomyConfig.fallback);
  });

  testWidgets('hatadan 30 sn sonra arka planda tekrar denenir, basarida guncellenir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final h = _Harness([
      const Failure(NetworkFailure()),
      Success(_response(boost: 55)),
    ]);

    await h.fetch();
    await tester.pump(const Duration(seconds: 29));
    expect(h.repo.calls, 1, reason: '30 sn dolmadan tekrar denenmemeli');

    await tester.pump(const Duration(seconds: 2));

    expect(h.repo.calls, 2);
    expect(h.state.core.boostCostGreen, 55);
  });
}

EconomyConfigResponse _response({required int boost}) {
  final json = EconomyConfig.fallback.toJson();
  final core = Map<String, dynamic>.from(json['core'] as Map<String, dynamic>)..['boostCostGreen'] = boost;
  return EconomyConfigResponse(version: 2, config: EconomyConfig.fromJson({...json, 'core': core}));
}

class _Harness {
  _Harness(List<Result<EconomyConfigResponse>> script) : repo = _FakeAppConfigRepository(script) {
    container = ProviderContainer(overrides: [appConfigRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
  }

  final _FakeAppConfigRepository repo;
  late final ProviderContainer container;

  Future<void> fetch() => container.read(economyConfigProvider.notifier).fetch();
  EconomyConfig get state => container.read(economyConfigProvider);
}

class _FakeAppConfigRepository implements AppConfigRepository {
  _FakeAppConfigRepository(this._script);

  final List<Result<EconomyConfigResponse>> _script;
  int calls = 0;

  @override
  Future<Result<EconomyConfigResponse>> getEconomyConfig() async {
    final result = _script[calls.clamp(0, _script.length - 1)];
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeAppConfigRepository.${invocation.memberName}');
}
