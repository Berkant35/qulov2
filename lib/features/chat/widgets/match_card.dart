import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/match_model.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  const MatchCard({super.key, required this.match, required this.onTap});

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
                    color: AppColors.secondary,
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
          match.lastMessage ?? u?.city ?? '',
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
                  color: hasUnread ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              )
            else if (u?.isOnline == true)
              Text(
                context.tr('online'),
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary),
              ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  match.unreadCount > 99 ? '99+' : '${match.unreadCount}',
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
      ),
    );
  }

  String _formatRelativeTime(BuildContext context, String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return context.tr('now');
      if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
      if (diff.inHours < 24) return '${diff.inHours}s';

      final today = DateTime(now.year, now.month, now.day);
      final messageDay = DateTime(dt.year, dt.month, dt.day);
      final dayDiff = today.difference(messageDay).inDays;

      if (dayDiff == 1) return context.tr('yesterday');
      if (dayDiff < 7) return '${dayDiff}g';

      return '${dt.day}.${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
