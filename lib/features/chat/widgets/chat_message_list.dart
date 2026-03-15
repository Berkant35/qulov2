import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_message_item.dart';

class ChatMessageList extends StatelessWidget {
  final AsyncValue<dynamic> chatState;
  final ScrollController scrollCtrl;
  final String? myId;
  final String matchId;
  final void Function(MessageModel msg, bool isMe) onLongPress;
  final Map<String, int> Function(List<MessageReaction>) groupReactions;

  const ChatMessageList({
    super.key,
    required this.chatState,
    required this.scrollCtrl,
    required this.myId,
    required this.matchId,
    required this.onLongPress,
    required this.groupReactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return chatState.when(
      loading: () => const Center(child: AppLoadingWidget.large()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (state) {
        if (state.messages.isEmpty) {
          return Center(
            child: Text(
              context.tr('say_hello'),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          controller: scrollCtrl,
          reverse: true,
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          itemCount: state.messages.length,
          itemBuilder: (_, i) {
            final msg = state.messages[i] as MessageModel;
            final isMe = msg.senderId == myId;
            final nextMsg =
                i < state.messages.length - 1 ? state.messages[i + 1] as MessageModel : null;

            return ChatMessageItem(
              message: msg,
              isMe: isMe,
              matchId: matchId,
              myId: myId,
              nextMessage: nextMsg,
              isLast: i == state.messages.length - 1,
              onLongPress: onLongPress,
              groupReactions: groupReactions,
            );
          },
        );
      },
    );
  }
}
