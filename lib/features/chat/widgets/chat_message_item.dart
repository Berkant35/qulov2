import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/features/chat/mixins/chat_message_item_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/chat_day_separator.dart';
import 'package:qulo_v2/features/chat/widgets/question_message_bubble.dart';
import 'package:qulo_v2/features/chat/widgets/regular_message_bubble.dart';

class ChatMessageItem extends StatelessWidget with ChatMessageItemMixin {
  final MessageModel message;
  final bool isMe;
  final String matchId;
  final MessageModel? nextMessage;
  final bool isLast;
  final void Function(MessageModel msg, bool isMe) onLongPress;
  final Map<String, int> Function(List<MessageReaction>) groupReactions;

  /// Whether to show the timestamp below this message.
  final bool showTimestamp;

  /// True when this message is the first (top) in its visual group.
  final bool isGroupStart;

  /// True when this message is the last (bottom) in its visual group.
  final bool isGroupEnd;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.matchId,
    required this.nextMessage,
    required this.isLast,
    required this.onLongPress,
    required this.groupReactions,
    this.showTimestamp = true,
    this.isGroupStart = true,
    this.isGroupEnd = true,
  });

  @override
  Widget build(BuildContext context) {
    final msgTime = DateTime.tryParse(message.createdAt ?? '');
    final timeStr = showTimestamp && msgTime != null ? context.fmt.time(msgTime) : '';
    final dayToSeparate =
        separatorDay(msgTime: msgTime, next: nextMessage, isLast: isLast);
    final questionId = message.questionId;

    return Column(
      children: [
        if (dayToSeparate != null) ChatDaySeparator(day: dayToSeparate),
        if (questionId != null)
          QuestionMessageBubble(
            questionId: questionId,
            isMe: isMe,
            matchId: matchId,
            timeStr: timeStr,
          )
        else
          RegularMessageBubble(
            message: message,
            isMe: isMe,
            timeStr: timeStr,
            onLongPress: onLongPress,
            groupReactions: groupReactions,
            isGroupStart: isGroupStart,
            isGroupEnd: isGroupEnd,
          ),
      ],
    );
  }
}
