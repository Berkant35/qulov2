import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'acquisition_service.g.dart';

@RestApi()
abstract class AcquisitionService {
  factory AcquisitionService(Dio dio) = _AcquisitionService;

  @GET('/acquisition/channels')
  Future<dynamic> getChannels();

  @POST('/acquisition/answer')
  Future<dynamic> submitAnswer(@Body() Map<String, dynamic> data);
}
