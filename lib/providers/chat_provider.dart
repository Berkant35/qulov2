import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

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

  Future<Result<MessageModel>> sendMessage(String content, {bool isImage = false}) async {
    final result = await ref.read(chatRepositoryProvider).sendMessage(arg, content: content, isImage: isImage);
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

  void addRealtimeMessage(MessageModel message) {
    final current = state.valueOrNull ?? const ChatState();
    state = AsyncData(current.copyWith(
      messages: [message, ...current.messages],
      total: current.total + 1,
    ));
  }
}

class ChatState {
  final List<MessageModel> messages;
  final int total;
  final int page;

  const ChatState({this.messages = const [], this.total = 0, this.page = 1});

  ChatState copyWith({List<MessageModel>? messages, int? total, int? page}) {
    return ChatState(
      messages: messages ?? this.messages,
      total: total ?? this.total,
      page: page ?? this.page,
    );
  }
}

final chatProvider = AsyncNotifierProvider.family<ChatNotifier, ChatState, String>(ChatNotifier.new);
