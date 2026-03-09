import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/match_model.dart';

part 'match_service.g.dart';

@RestApi()
abstract class MatchService {
  factory MatchService(Dio dio) = _MatchService;

  @GET('/matches/discover')
  Future<DiscoverResponse> discover(@Query('page') int page);

  @POST('/matches/swipe')
  Future<SwipeResponse> swipe(@Body() Map<String, dynamic> data);

  @GET('/matches/list')
  Future<List<MatchModel>> getMatches();

  @DELETE('/matches/{matchId}')
  Future<void> unmatch(@Path('matchId') String matchId);
}
