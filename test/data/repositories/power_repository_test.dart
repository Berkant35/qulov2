import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/power_service.dart';
import 'package:qulo_v2/data/models/power_model.dart';
import 'package:qulo_v2/data/repositories/power_repository.dart';

class _FakePowerService implements PowerService {
  _FakePowerService({this.powers = const [], this.error});

  final List<PowerModel> powers;
  final DioException? error;

  @override
  Future<List<PowerModel>> getPowers() async {
    if (error != null) throw error!;
    return powers;
  }
}

void main() {
  test('guc listesi oldugu gibi doner', () async {
    const powers = [
      PowerModel(id: 'p1', name: 'FIFTY_FIFTY', baseCost: 10),
      PowerModel(id: 'p2', name: 'HINT', baseCost: 5, isActive: false),
    ];

    final result = await PowerRepository(_FakePowerService(powers: powers)).getPowers();

    expect(result.when(success: (p) => p, failure: (_) => null), powers);
  });

  test('ag hatasi NetworkFailure', () async {
    final result = await PowerRepository(_FakePowerService(
      error: DioException(
        requestOptions: RequestOptions(path: '/powers'),
        type: DioExceptionType.connectionError,
      ),
    )).getPowers();

    expect(result.when(success: (_) => null, failure: (f) => f), isA<NetworkFailure>());
  });
}
