import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';

part 'user_service.g.dart';

@RestApi()
abstract class UserService {
  factory UserService(Dio dio) = _UserService;

  @GET('/users/me')
  Future<UserModel> getMe();

  @PATCH('/users/me')
  Future<UserModel> updateProfile(@Body() Map<String, dynamic> data);

  @PATCH('/users/me/details')
  Future<UserDetailsModel> updateDetails(@Body() Map<String, dynamic> data);

  @PATCH('/users/me/location')
  Future<void> updateLocation(@Body() Map<String, dynamic> data);

  @PATCH('/users/me/push-token')
  Future<void> updatePushToken(@Body() Map<String, dynamic> data);

  @POST('/users/me/heartbeat')
  Future<void> heartbeat();

  @DELETE('/users/me')
  Future<void> deleteAccount(@Body() Map<String, dynamic> body);

  @GET('/users/me/retention/eligibility')
  Future<dynamic> retentionEligibility(@Query('reason_code') String reasonCode);

  @POST('/users/me/retention/claim')
  Future<void> claimRetention(@Body() Map<String, dynamic> body);

  @GET('/users/{id}/profile')
  Future<PublicProfileModel> getPublicProfile(@Path('id') String userId);

  @GET('/users/me/notification-preferences')
  Future<dynamic> getNotificationPreferences();

  @PATCH('/users/me/notification-preferences')
  Future<dynamic> updateNotificationPreferences(
    @Body() Map<String, dynamic> body,
  );
}
