import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'page_message_service.g.dart';

@RestApi()
abstract class PageMessageRetrofitService {
  factory PageMessageRetrofitService(Dio dio) = _PageMessageRetrofitService;

  @GET('/page-messages')
  Future<dynamic> getMessages();

  @POST('/page-messages/{id}/event')
  Future<void> trackEvent(@Path('id') String id, @Body() Map<String, dynamic> body);
}
