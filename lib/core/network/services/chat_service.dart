import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:qulo_v2/data/models/media_request_model.dart';
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

  @DELETE('/chat/{matchId}/messages/{messageId}')
  Future<void> deleteMessage(
    @Path('matchId') String matchId,
    @Path('messageId') String messageId,
  );

  @POST('/chat/{matchId}/messages/{messageId}/reactions')
  Future<dynamic> addReaction(
    @Path('matchId') String matchId,
    @Path('messageId') String messageId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/chat/{matchId}/media-request')
  Future<MediaRequestModel> requestMedia(@Path('matchId') String matchId);

  @POST('/chat/{matchId}/media-request/{requestId}/respond')
  Future<dynamic> respondToMediaRequest(
    @Path('matchId') String matchId,
    @Path('requestId') String requestId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/chat/{matchId}/media-disable')
  Future<void> disableMedia(@Path('matchId') String matchId);

  @GET('/chat/{matchId}/media-status')
  Future<MediaStatusResponse> getMediaStatus(@Path('matchId') String matchId);
}
