import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'presence_service.g.dart';

@RestApi()
abstract class PresenceService {
  factory PresenceService(Dio dio) = _PresenceService;

  @POST('/users/me/presence')
  Future<void> heartbeat();

  @POST('/users/me/presence/offline')
  Future<void> goOffline();
}
