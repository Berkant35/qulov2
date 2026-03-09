import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/message_model.dart';

part 'chat_service.g.dart';

@RestApi()
abstract class ChatService {
  factory ChatService(Dio dio) = _ChatService;

  @GET('/chat/{matchId}/messages')
  Future<MessagesResponse> getMessages(
    @Path('matchId') String matchId,
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @POST('/chat/{matchId}/messages')
  Future<MessageModel> sendMessage(
    @Path('matchId') String matchId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/chat/{matchId}/read')
  Future<void> markAsRead(@Path('matchId') String matchId);
}
