import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/app_config_service.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';

class AppConfigRepository {
  final AppConfigRetrofitService _service;

  AppConfigRepository(this._service);

  Future<Result<AppConfigModel>> getConfig() async {
    try {
      final response = await _service.getConfig();
      return Success(AppConfigModel.fromJson(response));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
