import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'app_config_service.g.dart';

@RestApi()
abstract class AppConfigRetrofitService {
  factory AppConfigRetrofitService(Dio dio) = _AppConfigRetrofitService;

  @GET('/app/config')
  Future<dynamic> getConfig();

  @GET('/app/economy')
  Future<dynamic> getEconomyConfig();
}
