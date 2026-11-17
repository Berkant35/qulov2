import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/network/interceptors/request_timeout_interceptor.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';

part 'question_service.g.dart';

@RestApi()
abstract class QuestionService {
  factory QuestionService(Dio dio) = _QuestionService;

  @GET('/questions/me')
  Future<List<QuestionModel>> getMyQuestions();

  @POST('/questions/me')
  Future<QuestionModel> createQuestion(@Body() Map<String, dynamic> data);

  @PATCH('/questions/me/{orderNum}')
  Future<QuestionModel> updateQuestion(
    @Path('orderNum') int orderNum,
    @Body() Map<String, dynamic> data,
  );

  @DELETE('/questions/me/{orderNum}')
  Future<void> deleteQuestion(@Path('orderNum') int orderNum);

  @PATCH('/questions/me/reorder')
  Future<List<QuestionModel>> reorderQuestions(@Body() Map<String, dynamic> data);

  /// Multipart (`file` + `duration_ms`); govdeyi repository kurar.
  /// Yanit: guncel soru (GET /questions/me ogesiyle ayni sekil).
  @POST('/questions/me/{orderNum}/voice')
  @Extra({RequestTimeoutInterceptor.receiveTimeoutKey: AppDurations.mediaUploadReceiveTimeout})
  Future<QuestionModel> uploadVoice(
    @Path('orderNum') int orderNum,
    @Body() FormData data,
  );

  /// Sunucu senkron moderasyon yapar (<= 8 sn); uzun yanit siniri bu yuzden.
  @POST('/questions/me/{orderNum}/image')
  @Extra({RequestTimeoutInterceptor.receiveTimeoutKey: AppDurations.mediaUploadReceiveTimeout})
  Future<QuestionModel> uploadImage(
    @Path('orderNum') int orderNum,
    @Body() FormData data,
  );

  @DELETE('/questions/me/{orderNum}/media/{kind}')
  Future<void> deleteMedia(
    @Path('orderNum') int orderNum,
    @Path('kind') String kind,
  );

  @GET('/questions/me/analytics')
  Future<QuestionAnalyticsResponse> getAnalytics();

  @GET('/questions/me/weekly-report')
  Future<dynamic> getWeeklyReport();

  @POST('/questions/ai-suggest')
  Future<dynamic> getAiSuggestions(@Body() Map<String, dynamic> data);
}
