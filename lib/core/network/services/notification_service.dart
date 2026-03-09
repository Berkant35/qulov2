import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'notification_service.g.dart';

@RestApi()
abstract class NotificationRetrofitService {
  factory NotificationRetrofitService(Dio dio) = _NotificationRetrofitService;

  @GET('/notifications')
  Future<dynamic> getNotifications(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('/notifications/unread-count')
  Future<dynamic> getUnreadCount();

  @PATCH('/notifications/{id}/read')
  Future<void> markAsRead(@Path('id') String id);

  @POST('/notifications/read-all')
  Future<void> markAllAsRead();

  @POST('/notifications/{id}/click')
  Future<void> trackClick(@Path('id') String id);
}
