import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/media_request_model.dart';

class ChatAppBarTitle extends StatelessWidget {
  final String userName;
  final bool isOnline;
  final String statusText;
  final String? photoUrl;
  final VoidCallback? onTap;

  const ChatAppBarTitle({
    super.key,
    required this.userName,
    required this.isOnline,
    required this.statusText,
    this.photoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              backgroundImage: photoUrl != null
                  ? CachedNetworkImageProvider(photoUrl!)
                  : null,
              child: photoUrl == null
                  ? Icon(Icons.person, size: 20, color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.appColors.secondary,
                    border: Border.all(color: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (statusText.isNotEmpty)
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOnline
                        ? context.appColors.secondary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}

class ChatAppBarActions extends StatelessWidget {
  final bool mediaEnabled;
  final VoidCallback onUnmatch;
  final VoidCallback onMediaDisable;

  const ChatAppBarActions({
    super.key,
    required this.mediaEnabled,
    required this.onUnmatch,
    required this.onMediaDisable,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'unmatch') onUnmatch();
        if (value == 'media_disable') onMediaDisable();
      },
      itemBuilder: (ctx) {
        return [
          if (mediaEnabled)
            PopupMenuItem(
              value: 'media_disable',
              child: Row(
                children: [
                  Icon(Icons.no_photography,
                      color: context.appColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(ctx.tr('chat_disable_media')),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'unmatch',
            child: Row(
              children: [
                Icon(Icons.heart_broken, color: context.appColors.error, size: 20),
                const SizedBox(width: 8),
                Text(ctx.tr('unmatch')),
              ],
            ),
          ),
        ];
      },
    );
  }
}

/// App bar altında gösterilen medya isteği banner'ı.
class MediaRequestBanner extends StatelessWidget implements PreferredSizeWidget {
  final MediaRequestModel request;
  final String currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const MediaRequestBanner({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.onAccept,
    required this.onReject,
  });

  bool get _isMine => request.requesterId == currentUserId;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: context.appColors.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: _isMine
          ? const _SenderContent()
          : _ReceiverContent(onAccept: onAccept, onReject: onReject),
    );
  }
}

class _SenderContent extends StatelessWidget {
  const _SenderContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.hourglass_top, size: 18, color: context.appColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            AppLocalizations.of(context).get('chat_media_request_pending_short'),
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReceiverContent extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ReceiverContent({
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.camera_alt_outlined, size: 18, color: context.appColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            AppLocalizations.of(context).get('chat_media_sharing_request'),
            style: TextStyle(
              color: context.appColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: TextButton(
            onPressed: onReject,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              foregroundColor: context.appColors.textSecondary,
            ),
            child: Text(AppLocalizations.of(context).get('chat_reject'), style: const TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          height: 32,
          child: FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            child: Text(context.tr('media_accept'), style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
