import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_message_item.dart' show questionPrefix;

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const MatchCard({super.key, required this.match, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final u = match.user;
    final photo = u?.photos?.isNotEmpty == true ? u!.photos!.first : null;
    final theme = Theme.of(context);
    final hasUnread = match.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
              child: photo == null ? Icon(Icons.person, color: theme.hintColor) : null,
            ),
            if (u?.isOnline == true)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.appColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          u?.name ?? context.tr('unknown_user'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _displayLastMessage(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasUnread
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (match.lastMessageSentAt != null)
              Text(
                _formatRelativeTime(context, match.lastMessageSentAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: hasUnread ? context.appColors.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              )
            else if (u?.isOnline == true)
              Text(
                context.tr('online'),
                style: theme.textTheme.labelSmall?.copyWith(color: context.appColors.secondary),
              ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  match.unreadCount > 99 ? '99+' : context.fmt.integer(match.unreadCount),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  String _displayLastMessage(BuildContext context) {
    final msg = match.lastMessage;
    if (msg == null || msg.isEmpty) return match.user?.city ?? '';
    if (msg.startsWith(questionPrefix)) return '🎯 ${context.tr('chat_question_sent')}';
    return msg;
  }

  String _formatRelativeTime(BuildContext context, String isoTime) {
    final dt = DateTime.tryParse(isoTime);
    return dt == null ? '' : context.fmt.relativeShort(dt);
  }
}
