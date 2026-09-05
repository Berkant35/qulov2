import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/utils/text_utils.dart';
import 'package:qulo_v2/data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final meta = _typeMeta(notification.type, colors);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: notification.isRead
              ? null
              : colors.primarySurface.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Type Icon or Image ───
            _NotifLeading(
              notification: notification,
              meta: meta,
            ),
            const SizedBox(width: AppSpacing.md),

            // ─── Content ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (stripped of "Qulo" prefix)
                  Row(
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _cleanTitle(notification.title),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Body
                  Text(
                    sanitizeNotificationBody(
                      notification.body,
                      fallback: context.tr('notification_default_body'),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Timestamp + optional CTA
                  Row(
                    children: [
                      Text(
                        _timeAgo(context, notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      if (notification.actionLabel != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: onActionTap,
                          child: Text(
                            notification.actionLabel!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Strip "Qulo" or "Qulo:" prefix from notification titles
  String _cleanTitle(String title) {
    final cleaned = title
        .replaceFirst(RegExp(r'^Qulo\s*[:\-–—]?\s*', caseSensitive: false), '')
        .trim();
    return cleaned.isEmpty ? title : cleaned;
  }

  String _timeAgo(BuildContext context, String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    return dt == null ? '' : context.fmt.relative(dt);
  }
}

// ─── Notif Leading ─────────────────────────────────────────────────────────

class _NotifLeading extends StatelessWidget {
  final NotificationModel notification;
  final _NotifTypeMeta meta;

  const _NotifLeading({required this.notification, required this.meta});

  @override
  Widget build(BuildContext context) {
    if (notification.imageUrl != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: CachedNetworkImage(
              imageUrl: notification.imageUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              memCacheWidth: 144,
              placeholder: (_, __) => Container(
                width: 48,
                height: 48,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              errorWidget: (_, __, ___) => _TypeIconCircle(meta: meta, size: 48),
            ),
          ),
          // Small type badge
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: meta.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Icon(meta.icon, size: 10, color: Colors.white),
            ),
          ),
        ],
      );
    }

    return _TypeIconCircle(meta: meta, size: 44);
  }
}

// ─── Type Meta ─────────────────────────────────────────────────────────────

class _NotifTypeMeta {
  final IconData icon;
  final Color color;
  const _NotifTypeMeta({required this.icon, required this.color});
}

_NotifTypeMeta _typeMeta(String type, AppColorsResolved colors) {
  return switch (type) {
    'new_message' || 'new_message_image' => _NotifTypeMeta(
        icon: Icons.chat_bubble_rounded,
        color: colors.info,
      ),
    'new_match' => _NotifTypeMeta(
        icon: Icons.favorite_rounded,
        color: AppColors.matchPink,
      ),
    'quiz_started' => _NotifTypeMeta(
        icon: Icons.help_outline_rounded,
        color: colors.primary,
      ),
    'passport_expired' => _NotifTypeMeta(
        icon: Icons.flight_rounded,
        color: colors.warning,
      ),
    'campaign' => _NotifTypeMeta(
        icon: Icons.campaign_rounded,
        color: colors.secondary,
      ),
    _ => _NotifTypeMeta(
        icon: Icons.notifications_rounded,
        color: colors.primary,
      ),
  };
}

// ─── Type Icon Circle ──────────────────────────────────────────────────────

class _TypeIconCircle extends StatelessWidget {
  final _NotifTypeMeta meta;
  final double size;

  const _TypeIconCircle({required this.meta, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(meta.icon, color: meta.color, size: size * 0.45),
    );
  }
}
