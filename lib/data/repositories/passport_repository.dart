import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/passport_service.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class PassportRepository implements IPassportRepository {
  final PassportService _service;
  final NetworkManager _network;

  PassportRepository(this._service, this._network);

  @override
  Future<Result<Map<String, dynamic>>> activate({
    required String city,
    required double lat,
    required double lng,
  }) async {
    return _network.post('/passport/activate', data: {
      'city': city,
      'lat': lat,
      'lng': lng,
    });
  }

  @override
  Future<Result<void>> deactivate() async {
    try {
      await _service.deactivate();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
