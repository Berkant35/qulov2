import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'passport_service.g.dart';

@RestApi()
abstract class PassportService {
  factory PassportService(Dio dio) = _PassportService;

  @POST('/passport/deactivate')
  Future<void> deactivate();
}
