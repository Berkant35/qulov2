import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class MediaRequestCard extends StatelessWidget {
  final String requesterId;
  final String currentUserId;
  final String status;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const MediaRequestCard({
    super.key,
    required this.requesterId,
    required this.currentUserId,
    required this.status,
    this.onAccept,
    this.onReject,
  });

  bool get _isMine => requesterId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final IconData icon;
    final Color iconColor;

    switch (status) {
      case 'accepted':
        borderColor = context.appColors.success.withValues(alpha: 0.5);
        icon = Icons.check_circle_outline;
        iconColor = context.appColors.success;
      case 'rejected':
        borderColor = context.appColors.textHint.withValues(alpha: 0.4);
        icon = Icons.close;
        iconColor = context.appColors.textHint;
      default: // pending
        borderColor = context.appColors.primary.withValues(alpha: 0.4);
        icon = Icons.camera_alt_outlined;
        iconColor = context.appColors.primary;
    }

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppSpacing.sm),
          _MediaRequestContent(
            status: status,
            isMine: _isMine,
            onAccept: onAccept,
            onReject: onReject,
          ),
        ],
      ),
    );
  }
}

class _MediaRequestContent extends StatelessWidget {
  final String status;
  final bool isMine;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _MediaRequestContent({
    required this.status,
    required this.isMine,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (status) {
      case 'accepted':
        return Text(
          context.tr('media_active'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.success,
            fontWeight: FontWeight.w600,
          ),
        );
      case 'rejected':
        return Text(
          context.tr('media_rejected'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textHint,
          ),
        );
      default: // pending
        if (isMine) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('media_sent'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr('media_waiting'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('media_wants_share'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.appColors.textSecondary,
                        side: BorderSide(color: context.appColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: Text(context.tr('media_reject')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appColors.primary,
                        foregroundColor: context.appColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: Text(context.tr('media_accept')),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
    }
  }
}
