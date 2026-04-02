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
        child: Text(
          context.tr('chat_messages_error'),
          style: TextStyle(color: context.appColors.error),
        ),
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
          cacheExtent: 1500,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          itemCount: state.messages.length,
          itemBuilder: (_, i) {
            final msg = state.messages[i] as MessageModel;
            final isMe = msg.senderId == myId;
            final nextMsg =
                i < state.messages.length - 1 ? state.messages[i + 1] as MessageModel : null;
            // prevMsg = message displayed BELOW this one (reverse list: i-1)
            final prevMsg =
                i > 0 ? state.messages[i - 1] as MessageModel : null;

            // --- Grouping logic ---
            // Messages from the same sender within the same minute are grouped.
            final grouping = _computeGrouping(msg, prevMsg, nextMsg);

            return ChatMessageItem(
              message: msg,
              isMe: isMe,
              matchId: matchId,
              myId: myId,
              nextMessage: nextMsg,
              isLast: i == state.messages.length - 1,
              onLongPress: onLongPress,
              groupReactions: groupReactions,
              showTimestamp: grouping.showTimestamp,
              isGroupStart: grouping.isGroupStart,
              isGroupEnd: grouping.isGroupEnd,
            );
          },
        );
      },
    );
  }

  /// Determines grouping flags for a message.
  ///
  /// The list is reversed (index 0 = newest). So:
  /// - `prevMsg` (i-1) is the message displayed BELOW (newer / closer to bottom)
  /// - `nextMsg` (i+1) is the message displayed ABOVE (older / closer to top)
  ///
  /// Two consecutive messages are in the same group when:
  /// 1. Same sender
  /// 2. Both timestamps exist and fall within the same minute
  static _MessageGrouping _computeGrouping(
    MessageModel msg,
    MessageModel? prevMsg,
    MessageModel? nextMsg,
  ) {
    final sameGroupAsBelow = _isSameGroup(msg, prevMsg);
    final sameGroupAsAbove = _isSameGroup(msg, nextMsg);

    // isGroupStart = first message of a visual group (top-most in the group = closest to older msgs)
    // In the reversed list this means: no same-group message ABOVE (nextMsg).
    final isGroupStart = !sameGroupAsAbove;

    // isGroupEnd = last message of a visual group (bottom-most = closest to newer msgs)
    // In the reversed list this means: no same-group message BELOW (prevMsg).
    final isGroupEnd = !sameGroupAsBelow;

    // Show timestamp only on the last (bottom) message of the group.
    final showTimestamp = isGroupEnd;

    return _MessageGrouping(
      showTimestamp: showTimestamp,
      isGroupStart: isGroupStart,
      isGroupEnd: isGroupEnd,
    );
  }

  /// Returns true when both messages belong to the same visual group.
  static bool _isSameGroup(MessageModel a, MessageModel? b) {
    if (b == null) return false;
    if (a.senderId != b.senderId) return false;

    final tA = DateTime.tryParse(a.createdAt ?? '');
    final tB = DateTime.tryParse(b.createdAt ?? '');
    if (tA == null || tB == null) return false;

    // Same minute check
    final localA = tA.toLocal();
    final localB = tB.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day &&
        localA.hour == localB.hour &&
        localA.minute == localB.minute;
  }
}

class _MessageGrouping {
  final bool showTimestamp;
  final bool isGroupStart;
  final bool isGroupEnd;

  const _MessageGrouping({
    required this.showTimestamp,
    required this.isGroupStart,
    required this.isGroupEnd,
  });
}
