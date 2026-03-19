import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Displayed above the input bar when there is an active chat lock.
/// The input bar must be disabled and this banner tells the user to answer.
class ChatLockBanner extends StatelessWidget {
  const ChatLockBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          const Text('\ud83d\udd12', style: TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Mesaj göndermek için soruyu cevaplamanız gerekiyor.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
