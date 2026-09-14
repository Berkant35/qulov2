import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/features/chat/mixins/message_content_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/photo_message_widget.dart';
import 'package:qulo_v2/features/chat/widgets/voice_message_widget.dart';

/// Mesaj baloncugunun govdesi: silinmis / ses / foto / metin.
class MessageContent extends StatelessWidget with MessageContentMixin {
  final MessageModel message;
  final bool isMe;
  final bool hasReactions;
  final bool isGroupStart;
  final bool isGroupEnd;

  const MessageContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.hasReactions,
    this.isGroupStart = true,
    this.isGroupEnd = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = groupedBorderRadius(
      isMe: isMe,
      isGroupStart: isGroupStart,
      isGroupEnd: isGroupEnd,
    );
    // Tepki satiri ya da ayni gruptan sonraki baloncuk hemen altta: dar bosluk.
    final bottomMargin = hasReactions || !isGroupEnd ? 2.0 : AppSpacing.sm;

    if (message.isDeleted) {
      return Container(
        margin: EdgeInsets.only(bottom: bottomMargin),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: radius,
        ),
        child: Text(
          context.tr('chat_message_deleted'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (message.isAudio) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomMargin),
        child: VoiceMessageWidget(
          audioUrl: message.audioUrl!,
          durationSeconds: message.audioDurationSeconds ?? 0,
          isMine: isMe,
        ),
      );
    }

    if (message.isImage) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomMargin),
        child: PhotoMessageWidget(
          imageUrl: message.content,
          isMine: isMe,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        gradient: isMe ? context.appColors.primaryButtonGradient : null,
        color: isMe ? null : context.appColors.surfaceElevated,
        borderRadius: radius,
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
