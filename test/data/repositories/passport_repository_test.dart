import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/passport_service.dart';
import 'package:qulo_v2/data/repositories/passport_repository.dart';

/// Pasaport (Premium) kapatma. `activate` test edilmedi: Retrofit yerine
/// singleton `NetworkManager` uzerinden gidiyor, fake'lenemiyor
/// (`NetworkManager.guard` ortak yolu `network_manager_test`'te).
class _FakePassportService implements PassportService {
  _FakePassportService({this.error});

  final DioException? error;
  int calls = 0;

  @override
  Future<void> deactivate() async {
    calls++;
    if (error != null) throw error!;
  }
}

void main() {
  test('kapatma basarili — servis bir kez cagrilir', () async {
    final service = _FakePassportService();

    final result = await PassportRepository(service, NetworkManager.instance).deactivate();

    expect(result.isSuccess, isTrue);
    expect(service.calls, 1);
  });

  test('sunucu hatasi kodu ile doner — kullanici pasaportun kapandigini sanmasin', () async {
    final service = _FakePassportService(
      error: DioException(
        requestOptions: RequestOptions(path: '/passport/deactivate'),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/passport/deactivate'),
          statusCode: 403,
          data: {'error': {'code': 'PREMIUM_REQUIRED'}},
        ),
      ),
    );

    final result = await PassportRepository(service, NetworkManager.instance).deactivate();

    expect((result.when(success: (_) => null, failure: (f) => f) as ServerFailure).code,
        'PREMIUM_REQUIRED');
  });
}
