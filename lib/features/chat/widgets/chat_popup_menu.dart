import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class ChatPopupMenu extends StatelessWidget {
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final VoidCallback? onUnmatch;
  final VoidCallback? onMediaDisable;
  final bool mediaEnabled;

  const ChatPopupMenu({
    super.key,
    required this.onReport,
    required this.onBlock,
    this.onUnmatch,
    this.onMediaDisable,
    this.mediaEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'report':
            onReport();
          case 'block':
            onBlock();
          case 'unmatch':
            onUnmatch?.call();
          case 'media_disable':
            onMediaDisable?.call();
        }
      },
      itemBuilder: (ctx) {
        return [
          if (mediaEnabled && onMediaDisable != null)
            PopupMenuItem(
              value: 'media_disable',
              child: Row(
                children: [
                  Icon(Icons.no_photography,
                      color: context.appColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.get('chat_disable_media')),
                ],
              ),
            ),
          if (onUnmatch != null)
            PopupMenuItem(
              value: 'unmatch',
              child: Row(
                children: [
                  Icon(Icons.heart_broken,
                      color: context.appColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.get('unmatch')),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined,
                    color: context.appColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(l10n.get('report')),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                Icon(Icons.block, color: context.appColors.error, size: 20),
                const SizedBox(width: 8),
                Text(l10n.get('block')),
              ],
            ),
          ),
        ];
      },
    );
  }
}
