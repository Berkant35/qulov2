import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/power_model.dart';

part 'power_service.g.dart';

@RestApi()
abstract class PowerService {
  factory PowerService(Dio dio) = _PowerService;

  @GET('/powers')
  Future<List<PowerModel>> getPowers();
}
