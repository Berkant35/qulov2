import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/chat_service.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/media_request_model.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class ChatRepository implements IChatRepository {
  final ChatService _service;
  final NetworkManager _network;

  ChatRepository(this._service, this._network);

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
  Future<Result<MessageModel>> sendMessage(String matchId, {required String content, bool isImage = false, String? audioUrl, int? audioDurationSeconds}) async {
    try {
      final data = <String, dynamic>{
        'content': content,
        'is_image': isImage,
      };
      if (audioUrl != null) data['audio_url'] = audioUrl;
      if (audioDurationSeconds != null) data['audio_duration_seconds'] = audioDurationSeconds;
      final response = await _service.sendMessage(matchId, data);
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

  @override
  Future<Result<void>> deleteMessage(String matchId, String messageId) async {
    try {
      await _service.deleteMessage(matchId, messageId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> addReaction(String matchId, String messageId, String emoji) async {
    try {
      final response = await _service.addReaction(matchId, messageId, {'emoji': emoji});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<MediaRequestModel>> requestMedia(String matchId) async {
    try {
      final response = await _service.requestMedia(matchId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> respondToMediaRequest(String matchId, String requestId, String action) async {
    try {
      final response = await _service.respondToMediaRequest(matchId, requestId, {'action': action});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> disableMedia(String matchId) async {
    try {
      await _service.disableMedia(matchId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<MediaStatusResponse>> getMediaStatus(String matchId) async {
    try {
      final response = await _service.getMediaStatus(matchId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<String>> uploadMedia(String matchId, {Uint8List? bytes, File? file, required String mimeType}) async {
    final fileName = mimeType.startsWith('audio/') ? 'audio.m4a' : 'photo.jpg';
    final MultipartFile multipart;
    if (bytes != null) {
      multipart = MultipartFile.fromBytes(bytes, filename: fileName, contentType: DioMediaType.parse(mimeType));
    } else if (file != null) {
      multipart = await MultipartFile.fromFile(file.path, filename: fileName, contentType: DioMediaType.parse(mimeType));
    } else {
      return const Failure(UnknownFailure());
    }
    final formData = FormData.fromMap({'file': multipart});
    final result = await _network.upload<Map<String, dynamic>>('/chat/$matchId/upload', data: formData);
    return result.when(
      success: (data) => Success(data['url'] as String),
      failure: (f) => Failure(f),
    );
  }

  Future<Result<ChatQuestionModel>> createQuestion(String matchId, Map<String, dynamic> data) async {
    try {
      final response = await _service.createQuestion(matchId, data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<ChatQuestionModel>> getQuestion(String questionId) async {
    try {
      final response = await _service.getQuestion(questionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<ChatQuestionAnswerResponse>> answerQuestion(String questionId, Map<String, dynamic> data) async {
    try {
      final response = await _service.answerQuestion(questionId, data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<ChatQuestionAnswerResponse>> rescueQuestion(String questionId) async {
    try {
      final response = await _service.rescueQuestion(questionId);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<UsePowerResponse>> usePower(String questionId, String powerName) async {
    try {
      final response = await _service.usePower(questionId, {'power_name': powerName});
      return Success(UsePowerResponse.fromJson(response as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<HandleTimeoutResponse>> handleTimeout(String questionId) async {
    try {
      final response = await _service.handleTimeout(questionId);
      return Success(HandleTimeoutResponse.fromJson(response as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<List<ChatQuestionDraftModel>>> getDrafts() async {
    try {
      final response = await _service.getDrafts();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<ChatQuestionDraftModel>> saveDraft(Map<String, dynamic> data) async {
    try {
      final response = await _service.saveDraft(data);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> deleteDraft(String draftId) async {
    try {
      await _service.deleteDraft(draftId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<ChatQuestionHistoryResponse>> getHistory({int page = 1}) async {
    try {
      final response = await _service.getHistory(page);
      return Success(ChatQuestionHistoryResponse.fromJson(response as Map<String, dynamic>));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
