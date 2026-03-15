import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class ChatAppBarTitle extends StatelessWidget {
  final String userName;
  final bool isOnline;
  final String statusText;

  const ChatAppBarTitle({
    super.key,
    required this.userName,
    required this.isOnline,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? AppColors.secondary : theme.colorScheme.outline,
          ),
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
                        ? AppColors.secondary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
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
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Medya paylasimini kapat'),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'unmatch',
            child: Row(
              children: [
                Icon(Icons.heart_broken, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                const Text('Unmatch'),
              ],
            ),
          ),
        ];
      },
    );
  }
}
