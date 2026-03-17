import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'block_service.g.dart';

@RestApi()
abstract class BlockService {
  factory BlockService(Dio dio) = _BlockService;

  @POST('/blocks')
  Future<void> blockUser(@Body() Map<String, dynamic> data);

  @DELETE('/blocks/{userId}')
  Future<void> unblockUser(@Path('userId') String userId);
}
