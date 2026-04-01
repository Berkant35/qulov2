import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/auth_model.dart';

part 'auth_service.g.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio) = _AuthService;

  @POST('/auth/register')
  Future<RegisterResponse> register(@Body() Map<String, dynamic> body);

  @POST('/auth/login')
  Future<AuthTokens> login(@Body() Map<String, dynamic> body);

  @POST('/auth/verify-email')
  Future<void> verifyEmail(@Body() Map<String, dynamic> body);

  @POST('/auth/refresh')
  Future<RefreshResponse> refresh(@Body() Map<String, dynamic> body);

  @POST('/auth/logout')
  Future<void> logout(@Body() Map<String, dynamic> body);

  @POST('/auth/forgot-password')
  Future<void> forgotPassword(@Body() Map<String, dynamic> body);

  @POST('/auth/reset-password')
  Future<void> resetPassword(@Body() Map<String, dynamic> body);

  @POST('/auth/social-login')
  Future<SocialLoginResponse> socialLogin(@Body() Map<String, dynamic> body);

  @POST('/users/me/complete-profile')
  Future<void> completeProfile(@Body() Map<String, dynamic> body);
}
