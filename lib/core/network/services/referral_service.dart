import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/referral_model.dart';

part 'referral_service.g.dart';

@RestApi()
abstract class ReferralService {
  factory ReferralService(Dio dio) = _ReferralService;

  @GET('/referrals/my-code')
  Future<Map<String, dynamic>> getMyCode();

  @GET('/referrals/stats')
  Future<ReferralStats> getStats();

  @GET('/referrals/history')
  Future<List<ReferralItem>> getHistory();

  @POST('/referrals/validate-code')
  Future<ValidateCodeResponse> validateCode(@Body() Map<String, dynamic> data);
}
