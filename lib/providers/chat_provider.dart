import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/media_request_model.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

class ChatNotifier extends FamilyAsyncNotifier<ChatState, String> {
  @override
  Future<ChatState> build(String matchId) async {
    return const ChatState();
  }

  Future<void> loadMessages({int page = 1}) async {
    state = const AsyncLoading();
    final result = await ref.read(chatRepositoryProvider).getMessages(arg, page: page);
    state = result.when(
      success: (response) => AsyncData(ChatState(
        messages: response.messages,
        total: response.total,
        page: response.page,
      )),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<Result<MessageModel>> sendMessage(String content, {bool isImage = false, String? audioUrl, int? audioDurationSeconds}) async {
    final result = await ref.read(chatRepositoryProvider).sendMessage(arg, content: content, isImage: isImage, audioUrl: audioUrl, audioDurationSeconds: audioDurationSeconds);
    result.when(
      success: (message) {
        final current = state.valueOrNull ?? const ChatState();
        state = AsyncData(current.copyWith(
          messages: [message, ...current.messages],
          total: current.total + 1,
        ));
      },
      failure: (_) {},
    );
    return result;
  }

  Future<void> markAsRead() async {
    await ref.read(chatRepositoryProvider).markAsRead(arg);
  }

  bool get hasMore {
    final current = state.valueOrNull;
    if (current == null) return false;
    return current.messages.length < current.total;
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !hasMore) return;

    final nextPage = current.page + 1;
    final result = await ref.read(chatRepositoryProvider).getMessages(arg, page: nextPage);
    result.when(
      success: (response) {
        final latest = state.valueOrNull;
        if (latest != null) {
          state = AsyncData(latest.copyWith(
            messages: [...latest.messages, ...response.messages],
            total: response.total,
            page: nextPage,
          ));
        }
      },
      failure: (_) {},
    );
  }

  void addRealtimeMessage(MessageModel message) {
    final current = state.valueOrNull ?? const ChatState();
    state = AsyncData(current.copyWith(
      messages: [message, ...current.messages],
      total: current.total + 1,
    ));
  }

  Future<void> addReaction(String messageId, String emoji) async {
    final result = await ref.read(chatRepositoryProvider).addReaction(arg, messageId, emoji);
    result.when(
      success: (_) {
        final current = state.valueOrNull ?? const ChatState();
        final userId = ref.read(authProvider).userId ?? '';
        final updatedMessages = current.messages.map((msg) {
          if (msg.id != messageId) return msg;
          final existing = msg.reactions ?? [];
          final newReaction = MessageReaction(emoji: emoji, userId: userId);
          return MessageModel(
            id: msg.id,
            matchId: msg.matchId,
            senderId: msg.senderId,
            content: msg.content,
            isImage: msg.isImage,
            readAt: msg.readAt,
            deletedAt: msg.deletedAt,
            audioUrl: msg.audioUrl,
            audioDurationSeconds: msg.audioDurationSeconds,
            reactions: [...existing, newReaction],
            createdAt: msg.createdAt,
          );
        }).toList();
        state = AsyncData(current.copyWith(messages: updatedMessages));
      },
      failure: (_) {},
    );
  }

  Future<void> loadMediaStatus() async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.getMediaStatus(arg);
    result.when(
      success: (status) {
        final current = state.valueOrNull ?? const ChatState();
        state = AsyncData(current.copyWith(
          mediaEnabled: status.mediaEnabled,
          pendingMediaRequest: status.pendingRequest,
        ));
      },
      failure: (_) {},
    );
  }

  Future<Result<MediaRequestModel>> requestMedia() async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.requestMedia(arg);
    result.when(
      success: (request) {
        final current = state.valueOrNull ?? const ChatState();
        state = AsyncData(current.copyWith(
          pendingMediaRequest: request,
        ));
      },
      failure: (_) {},
    );
    return result;
  }

  Future<void> respondToMediaRequest(String requestId, String action) async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.respondToMediaRequest(arg, requestId, action);
    result.when(
      success: (response) {
        final enabled = response['media_enabled'] == true;
        final current = state.valueOrNull ?? const ChatState();
        state = AsyncData(current.copyWith(
          mediaEnabled: enabled,
          clearPendingMediaRequest: true,
        ));
      },
      failure: (_) {},
    );
  }

  /// Updates the chat-lock state based on whether there is an unanswered
  /// chat-locked question where [currentUserId] is the answerer (not sender).
  void updateChatLock({
    required String currentUserId,
    required Map<String, ChatQuestionModel> questionCache,
  }) {
    final current = state.valueOrNull ?? const ChatState();
    // Find any message that is a question marker
    const prefix = '__QUESTION__:';
    bool locked = false;
    for (final msg in current.messages) {
      if (!msg.content.startsWith(prefix)) continue;
      final qId = msg.content.replaceFirst(prefix, '');
      final question = questionCache[qId];
      if (question == null) continue;
      if (question.hasChatLock &&
          !question.isAnswered &&
          question.senderId != currentUserId) {
        locked = true;
        break;
      }
    }
    if (locked != current.hasChatLock) {
      state = AsyncData(current.copyWith(hasChatLock: locked));
    }
  }

  Future<void> disableMedia() async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.disableMedia(arg);
    final current = state.valueOrNull ?? const ChatState();
    state = AsyncData(current.copyWith(
      mediaEnabled: false,
      clearPendingMediaRequest: true,
    ));
  }

  Future<void> deleteMessage(String messageId) async {
    final result = await ref.read(chatRepositoryProvider).deleteMessage(arg, messageId);
    result.when(
      success: (_) {
        final current = state.valueOrNull ?? const ChatState();
        final updatedMessages = current.messages.map((msg) {
          if (msg.id != messageId) return msg;
          return MessageModel(
            id: msg.id,
            matchId: msg.matchId,
            senderId: msg.senderId,
            content: msg.content,
            isImage: msg.isImage,
            readAt: msg.readAt,
            deletedAt: DateTime.now().toIso8601String(),
            audioUrl: msg.audioUrl,
            audioDurationSeconds: msg.audioDurationSeconds,
            reactions: msg.reactions,
            createdAt: msg.createdAt,
          );
        }).toList();
        state = AsyncData(current.copyWith(messages: updatedMessages));
      },
      failure: (_) {},
    );
  }
}

class ChatState {
  final List<MessageModel> messages;
  final int total;
  final int page;
  final bool mediaEnabled;
  final MediaRequestModel? pendingMediaRequest;
  /// True when there is an unanswered chat-locked question that the current
  /// user must answer before they can send new messages.
  final bool hasChatLock;

  const ChatState({
    this.messages = const [],
    this.total = 0,
    this.page = 1,
    this.mediaEnabled = false,
    this.pendingMediaRequest,
    this.hasChatLock = false,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    int? total,
    int? page,
    bool? mediaEnabled,
    MediaRequestModel? pendingMediaRequest,
    bool clearPendingMediaRequest = false,
    bool? hasChatLock,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      total: total ?? this.total,
      page: page ?? this.page,
      mediaEnabled: mediaEnabled ?? this.mediaEnabled,
      pendingMediaRequest: clearPendingMediaRequest
          ? null
          : (pendingMediaRequest ?? this.pendingMediaRequest),
      hasChatLock: hasChatLock ?? this.hasChatLock,
    );
  }
}

final chatProvider = AsyncNotifierProvider.family<ChatNotifier, ChatState, String>(ChatNotifier.new);

/// Cache for chat questions fetched by ID — avoids re-fetching on every rebuild.
final chatQuestionCacheProvider =
    StateProvider<Map<String, ChatQuestionModel>>((ref) => {});

/// Provider that fetches a single chat question by ID.
/// autoDispose ensures fresh data when widget rebuilds.
final chatQuestionProvider =
    FutureProvider.autoDispose.family<ChatQuestionModel?, String>((ref, questionId) async {
  // Always fetch from API — cache only used as fallback
  try {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.getQuestion(questionId);
    return result.when(
      success: (question) {
        ref.read(chatQuestionCacheProvider.notifier).update((state) {
          final copy = Map<String, ChatQuestionModel>.from(state);
          copy[questionId] = question;
          return copy;
        });
        return question;
      },
      failure: (_) {
        final cache = ref.read(chatQuestionCacheProvider);
        return cache[questionId];
      },
    );
  } catch (_) {
    final cache = ref.read(chatQuestionCacheProvider);
    return cache[questionId];
  }
});
