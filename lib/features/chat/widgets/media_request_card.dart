import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    final Color borderColor;
    final IconData icon;
    final Color iconColor;

    switch (status) {
      case 'accepted':
        borderColor = AppColors.success.withValues(alpha: 0.5);
        icon = Icons.check_circle_outline;
        iconColor = AppColors.success;
      case 'rejected':
        borderColor = AppColors.textHint.withValues(alpha: 0.4);
        icon = Icons.close;
        iconColor = AppColors.textHint;
      default: // pending
        borderColor = AppColors.primary.withValues(alpha: 0.4);
        icon = Icons.camera_alt_outlined;
        iconColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppSpacing.sm),
          _buildContent(theme),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (status) {
      case 'accepted':
        return Text(
          'Medya paylaşımı aktif',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        );
      case 'rejected':
        return Text(
          'Medya isteği reddedildi',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textHint,
          ),
        );
      default: // pending
        if (_isMine) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Medya isteği gönderildi',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cevap bekleniyor...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
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
                '\u{1F4F7} Medya paylaşmak istiyor',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
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
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: const Text('Kabul Et'),
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
