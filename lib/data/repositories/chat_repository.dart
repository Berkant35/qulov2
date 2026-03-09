import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/chat_service.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class ChatRepository implements IChatRepository {
  final ChatService _service;

  ChatRepository(this._service);

  @override
  Future<Result<MessagesResponse>> getMessages(String matchId, {int page = 1, int limit = 30}) async {
    try {
      final response = await _service.getMessages(matchId, page, limit);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<MessageModel>> sendMessage(String matchId, {required String content, bool isImage = false}) async {
    try {
      final response = await _service.sendMessage(matchId, {
        'content': content,
        'is_image': isImage,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> markAsRead(String matchId) async {
    try {
      await _service.markAsRead(matchId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
