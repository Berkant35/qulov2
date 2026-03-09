import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'report_service.g.dart';

@RestApi()
abstract class ReportService {
  factory ReportService(Dio dio) = _ReportService;

  @POST('/reports')
  Future<void> createReport(@Body() Map<String, dynamic> data);
}
