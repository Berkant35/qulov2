import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/app_config_service.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';
import 'package:qulo_v2/data/repositories/app_config_repository.dart';

/// Surum/bakim kapisinin veri kaynagi.
///
/// Sozlesme camelCase: qulo-server `app-config.service.ts` → `getConfig`
/// DB'deki snake_case kolonlari platforma gore secip camelCase donduruyor.
/// Mobil modeli `@JsonSerializable()` varsayilaniyla (anahtar = alan adi).
class _FakeAppConfigService implements AppConfigRetrofitService {
  _FakeAppConfigService({this.response, this.error});

  final dynamic response;
  final DioException? error;

  @override
  Future<dynamic> getConfig() async {
    if (error != null) throw error!;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAppConfigService.${invocation.memberName}');
}

Map<String, dynamic> _serverResponse({String? maintenanceMessage}) => {
      'minVersion': '2.0.9',
      'latestVersion': '2.0.10',
      'storeUrl': 'https://apps.apple.com/app/qulo',
      'isMaintenance': maintenanceMessage != null,
      'maintenanceMessage': maintenanceMessage,
      'isForceUpdateEnabled': true,
    };

AppFailure? _failureOf(Result<AppConfigModel> r) =>
    r.when(success: (_) => null, failure: (f) => f);

void main() {
  test('sunucu yaniti (camelCase) modele eksiksiz parse edilir', () async {
    final result =
        await AppConfigRepository(_FakeAppConfigService(response: _serverResponse())).getConfig();

    final config = result.when(success: (c) => c, failure: (_) => null)!;
    expect(config.minVersion, '2.0.9');
    expect(config.latestVersion, '2.0.10');
    expect(config.storeUrl, 'https://apps.apple.com/app/qulo');
    expect(config.isForceUpdateEnabled, isTrue);
    expect(config.isMaintenance, isFalse);
    expect(config.maintenanceMessage, isNull);
  });

  test('bakim mesaji varken tasinir', () async {
    final result = await AppConfigRepository(
      _FakeAppConfigService(response: _serverResponse(maintenanceMessage: 'Bakimdayiz')),
    ).getConfig();

    final config = result.when(success: (c) => c, failure: (_) => null)!;
    expect(config.isMaintenance, isTrue);
    expect(config.maintenanceMessage, 'Bakimdayiz');
  });

  test('snake_case (sozlesme disi) yanit cokmez — UnknownFailure', () async {
    // Sunucu anahtar bicimini degistirirse kapi fail-open calisir
    // (provider none doner); burada sadece throw olmadigi dondurulur.
    final result = await AppConfigRepository(_FakeAppConfigService(response: {
      'min_version': '2.0.9',
      'latest_version': '2.0.10',
      'store_url': 'x',
      'is_maintenance': false,
      'is_force_update_enabled': true,
    })).getConfig();

    expect(_failureOf(result), isA<UnknownFailure>());
  });

  test('sunucu hatasi kodu ile ServerFailure olur', () async {
    final result = await AppConfigRepository(_FakeAppConfigService(
      error: DioException(
        requestOptions: RequestOptions(path: '/app/config'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/app/config'),
          statusCode: 500,
          data: {'error': {'code': 'INTERNAL_ERROR'}},
        ),
      ),
    )).getConfig();

    expect((_failureOf(result) as ServerFailure).code, 'INTERNAL_ERROR');
  });
}
