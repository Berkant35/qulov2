import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';

part 'diamond_service.g.dart';

@RestApi()
abstract class DiamondService {
  factory DiamondService(Dio dio) = _DiamondService;

  @GET('/diamonds/balance')
  Future<DiamondBalance> getBalance();

  @GET('/diamonds/history')
  Future<DiamondHistoryResponse> getHistory(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST('/diamonds/purchase')
  Future<void> purchase(@Body() Map<String, dynamic> data);
}
