import 'package:flutter/material.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/features/chat/widgets/message_content.dart';
import 'package:qulo_v2/features/chat/widgets/message_timestamp.dart';
import 'package:qulo_v2/features/chat/widgets/reactions_row.dart';

/// Metin / foto / ses mesaji: icerik + tepkiler + (varsa) saat.
/// Silinmemis mesajda uzun basma mesaj menusunu acar.
class RegularMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String timeStr;
  final void Function(MessageModel msg, bool isMe) onLongPress;
  final Map<String, int> Function(List<MessageReaction>) groupReactions;
  final bool isGroupStart;
  final bool isGroupEnd;

  const RegularMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timeStr,
    required this.onLongPress,
    required this.groupReactions,
    this.isGroupStart = true,
    this.isGroupEnd = true,
  });

  @override
  Widget build(BuildContext context) {
    final reactions = message.reactions;
    final hasReactions = reactions != null && reactions.isNotEmpty;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            message.isDeleted ? null : () => onLongPress(message, isMe),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MessageContent(
              message: message,
              isMe: isMe,
              hasReactions: hasReactions,
              isGroupStart: isGroupStart,
              isGroupEnd: isGroupEnd,
            ),
            if (hasReactions)
              ReactionsRow(
                reactions: reactions,
                groupReactions: groupReactions,
              ),
            if (timeStr.isNotEmpty) MessageTimestamp(text: timeStr),
          ],
        ),
      ),
    );
  }
}
