import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_message.dart';
import 'package:qulo_v2/features/chat/widgets/message_timestamp.dart';

/// Sohbet akisindaki soru mesaji: soru karti + (varsa) saat.
class QuestionMessageBubble extends StatelessWidget {
  final String questionId;
  final bool isMe;
  final String matchId;
  final String timeStr;

  const QuestionMessageBubble({
    super.key,
    required this.questionId,
    required this.isMe,
    required this.matchId,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatQuestionMessage(
            questionId: questionId,
            matchId: matchId,
            isMe: isMe,
          ),
          if (timeStr.isNotEmpty)
            MessageTimestamp(text: timeStr, topPadding: AppSpacing.xs),
        ],
      ),
    );
  }
}
