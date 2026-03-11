import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
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

  @GET('/questions/me/analytics')
  Future<QuestionAnalyticsResponse> getAnalytics();

  @GET('/questions/me/weekly-report')
  Future<dynamic> getWeeklyReport();

  @POST('/questions/ai-suggest')
  Future<dynamic> getAiSuggestions(@Body() Map<String, dynamic> data);
}
