import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';

part 'chat_question_service.g.dart';

@RestApi()
abstract class ChatQuestionService {
  factory ChatQuestionService(Dio dio) = _ChatQuestionService;

  @POST('/chat/{matchId}/questions')
  Future<ChatQuestionModel> createQuestion(
    @Path('matchId') String matchId,
    @Body() Map<String, dynamic> data,
  );

  @GET('/chat/questions/{questionId}')
  Future<ChatQuestionModel> getQuestion(
    @Path('questionId') String questionId,
  );

  @POST('/chat/questions/{questionId}/answer')
  Future<ChatQuestionAnswerResponse> answerQuestion(
    @Path('questionId') String questionId,
    @Body() Map<String, dynamic> data,
  );
}
