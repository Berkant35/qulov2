import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/models/quiz_summary_model.dart';

part 'quiz_service.g.dart';

@RestApi()
abstract class QuizService {
  factory QuizService(Dio dio) = _QuizService;

  @POST('/quiz/start')
  Future<QuizStartResponse> startSession(@Body() Map<String, dynamic> data);

  @GET('/quiz/{sessionId}')
  Future<QuizQuestionModel> getCurrentQuestion(
    @Path('sessionId') String sessionId,
  );

  @POST('/quiz/{sessionId}/answer')
  Future<QuizAnswerResponse> answerQuestion(
    @Path('sessionId') String sessionId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/quiz/{sessionId}/rescue')
  Future<QuizAnswerResponse> rescueWithSkip(
    @Path('sessionId') String sessionId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/quiz/{sessionId}/fail')
  Future<QuizAnswerResponse> failSession(
    @Path('sessionId') String sessionId,
  );

  @GET('/quiz/{sessionId}/result')
  Future<QuizResultModel> getSessionResult(
    @Path('sessionId') String sessionId,
  );

  @GET('/quiz/match/{matchId}/summary')
  Future<QuizSummaryModel?> getMatchQuizSummary(
    @Path('matchId') String matchId,
  );
}
