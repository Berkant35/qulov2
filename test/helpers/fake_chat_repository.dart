import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/media_request_model.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/data/repositories/chat_repository.dart';

/// Sohbet deposu: cevaplar sabit, `*Gate` verilen cagri o tamamlanana kadar
/// bekler — ekran await sirasinda kapatilinca (async-gap) ne oldugunu sinamak
/// icin. Kullanilmayan metotlar noSuchMethod ile patlar.
class FakeChatRepository implements ChatRepository {
  Result<MessageModel> sendResult = Success(MessageModel(
    id: 'sent',
    matchId: 'm1',
    senderId: 'me',
    content: 'selam',
    createdAt: '2026-10-12T10:00:00Z',
  ));
  Completer<void>? sendGate;
  final sentContents = <String>[];

  Result<MediaStatusResponse> mediaStatus = const Success(MediaStatusResponse(
    mediaEnabled: false,
    myEnabled: false,
    otherEnabled: false,
  ));
  Completer<void>? mediaStatusGate;
  int mediaStatusCalls = 0;

  Result<ChatQuestionModel> createQuestionResult = const Success(ChatQuestionModel(
    id: 'q-new',
    matchId: 'm1',
    senderId: 'me',
    questionText: 'En sevdigim sehir?',
    optionA: 'Izmir',
    optionB: 'Ankara',
    createdAt: '2026-10-12T10:00:00Z',
  ));
  Completer<void>? createQuestionGate;

  Result<ChatQuestionAnswerResponse> answerResult =
      const Success(ChatQuestionAnswerResponse(isCorrect: false, unmatched: false));
  Completer<void>? answerGate;

  List<ChatQuestionDraftModel> drafts = const [];
  Result<void> deleteDraftResult = const Success(null);
  Completer<void>? deleteDraftGate;
  final deletedDraftIds = <String>[];

  Result<String> questionMediaResult = const Success('https://cdn.test/reward.jpg');
  Completer<void>? questionMediaGate;

  int getMessagesCalls = 0;

  @override
  Future<Result<MessagesResponse>> getMessages(String matchId, {int page = 1, int limit = 30}) async {
    getMessagesCalls++;
    return Success(MessagesResponse(messages: const [], total: 0, page: page, limit: limit));
  }

  @override
  Future<Result<void>> markAsRead(String matchId) async => const Success(null);

  @override
  Future<Result<MediaStatusResponse>> getMediaStatus(String matchId) async {
    mediaStatusCalls++;
    await mediaStatusGate?.future;
    return mediaStatus;
  }

  @override
  Future<Result<MessageModel>> sendMessage(
    String matchId, {
    required String content,
    bool isImage = false,
    String? audioUrl,
    int? audioDurationSeconds,
  }) async {
    sentContents.add(content);
    await sendGate?.future;
    return sendResult;
  }

  @override
  Future<Result<ChatQuestionModel>> createQuestion(String matchId, Map<String, dynamic> data) async {
    await createQuestionGate?.future;
    return createQuestionResult;
  }

  @override
  Future<Result<ChatQuestionAnswerResponse>> answerQuestion(
    String questionId,
    Map<String, dynamic> data,
  ) async {
    await answerGate?.future;
    return answerResult;
  }

  @override
  Future<Result<String>> uploadQuestionMedia(
    String matchId, {
    Uint8List? bytes,
    File? file,
    required String mimeType,
  }) async {
    await questionMediaGate?.future;
    return questionMediaResult;
  }

  @override
  Future<Result<List<ChatQuestionDraftModel>>> getDrafts() async => Success(drafts);

  @override
  Future<Result<ChatQuestionHistoryResponse>> getHistory({int page = 1}) async =>
      Success(ChatQuestionHistoryResponse(items: const [], total: 0, page: page, limit: 20));

  @override
  Future<Result<void>> deleteDraft(String draftId) async {
    deletedDraftIds.add(draftId);
    await deleteDraftGate?.future;
    return deleteDraftResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeChatRepository.${invocation.memberName}');
}
