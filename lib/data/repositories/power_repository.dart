import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/power_service.dart';
import 'package:qulo_v2/data/models/power_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class PowerRepository implements IPowerRepository {
  final PowerService _service;

  PowerRepository(this._service);

  @override
  Future<Result<List<PowerModel>>> getPowers() async {
    try {
      final response = await _service.getPowers();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
