import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_day_separator.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_message.dart';
import 'package:qulo_v2/features/chat/widgets/photo_message_widget.dart';
import 'package:qulo_v2/features/chat/widgets/voice_message_widget.dart';

/// Prefix used by the backend to mark question messages.
const questionPrefix = '__QUESTION__:';

class ChatMessageItem extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String matchId;
  final String? myId;
  final MessageModel? nextMessage;
  final bool isLast;
  final void Function(MessageModel msg, bool isMe) onLongPress;
  final Map<String, int> Function(List<MessageReaction>) groupReactions;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.matchId,
    required this.myId,
    required this.nextMessage,
    required this.isLast,
    required this.onLongPress,
    required this.groupReactions,
  });

  @override
  Widget build(BuildContext context) {
    final hasReactions =
        message.reactions != null && message.reactions!.isNotEmpty;
    final msgTime = DateTime.tryParse(message.createdAt ?? '');
    final timeStr = msgTime != null
        ? '${msgTime.toLocal().hour.toString().padLeft(2, '0')}:${msgTime.toLocal().minute.toString().padLeft(2, '0')}'
        : '';

    // Day separator logic (reverse list: check if next item is different day)
    Widget? daySeparator;
    if (nextMessage != null) {
      final nextTime = DateTime.tryParse(nextMessage!.createdAt ?? '');
      if (msgTime != null && nextTime != null) {
        final msgDay = DateTime(
            msgTime.toLocal().year, msgTime.toLocal().month, msgTime.toLocal().day);
        final nextDay = DateTime(
            nextTime.toLocal().year, nextTime.toLocal().month, nextTime.toLocal().day);
        if (msgDay != nextDay) {
          daySeparator = ChatDaySeparator(day: msgDay);
        }
      }
    } else if (isLast && msgTime != null) {
      daySeparator = ChatDaySeparator(
        day: DateTime(
            msgTime.toLocal().year, msgTime.toLocal().month, msgTime.toLocal().day),
      );
    }

    final isQuestionMsg = message.content.startsWith(questionPrefix);

    return Column(
      children: [
        if (daySeparator != null) daySeparator,
        if (isQuestionMsg)
          _QuestionMessageBubble(
            message: message,
            isMe: isMe,
            matchId: matchId,
            timeStr: timeStr,
          )
        else
          _RegularMessageBubble(
            message: message,
            isMe: isMe,
            hasReactions: hasReactions,
            timeStr: timeStr,
            onLongPress: onLongPress,
            groupReactions: groupReactions,
          ),
      ],
    );
  }
}

class _QuestionMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String matchId;
  final String timeStr;

  const _QuestionMessageBubble({
    required this.message,
    required this.isMe,
    required this.matchId,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatQuestionMessage(
            questionId: message.content.replaceFirst(questionPrefix, ''),
            matchId: matchId,
            isMe: isMe,
          ),
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                timeStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RegularMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool hasReactions;
  final String timeStr;
  final void Function(MessageModel msg, bool isMe) onLongPress;
  final Map<String, int> Function(List<MessageReaction>) groupReactions;

  const _RegularMessageBubble({
    required this.message,
    required this.isMe,
    required this.hasReactions,
    required this.timeStr,
    required this.onLongPress,
    required this.groupReactions,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            message.isDeleted ? null : () => onLongPress(message, isMe),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _MessageContent(
              message: message,
              isMe: isMe,
              hasReactions: hasReactions,
            ),
            if (hasReactions)
              _ReactionsRow(
                reactions: message.reactions!,
                groupReactions: groupReactions,
              ),
            if (timeStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  timeStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool hasReactions;

  const _MessageContent({
    required this.message,
    required this.isMe,
    required this.hasReactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isDeleted) {
      return Container(
        margin: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Text(
          'Bu mesaj silindi',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (message.isAudio) {
      return Padding(
        padding: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
        child: VoiceMessageWidget(
          audioUrl: message.audioUrl!,
          durationSeconds: message.audioDurationSeconds ?? 0,
          isMine: isMe,
        ),
      );
    }

    if (message.isImage) {
      return Padding(
        padding: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
        child: PhotoMessageWidget(
          imageUrl: message.content,
          isMine: isMe,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: hasReactions ? 2 : AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        gradient: isMe ? AppColors.primaryButtonGradient : null,
        color: isMe ? null : context.appColors.surfaceElevated,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Text(
        message.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color:
              isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  final List<MessageReaction> reactions;
  final Map<String, int> Function(List<MessageReaction>) groupReactions;

  const _ReactionsRow({
    required this.reactions,
    required this.groupReactions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: groupReactions(reactions).entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.appColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              entry.value > 1 ? '${entry.key} ${entry.value}' : entry.key,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }
}
