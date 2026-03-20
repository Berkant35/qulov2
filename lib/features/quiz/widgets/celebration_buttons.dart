import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class CelebrationButtons extends StatelessWidget {
  final bool matched;
  final VoidCallback? onStartChat;
  final VoidCallback onGoBack;

  const CelebrationButtons({
    super.key,
    required this.matched,
    this.onStartChat,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (matched && onStartChat != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                AnalyticsManager.instance.logEvent(
                  AnalyticsEvents.matchCelebrationStartChat,
                );
                onStartChat?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                context.tr('quiz_send_message'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              AnalyticsManager.instance.logEvent(
                AnalyticsEvents.matchCelebrationGoBack,
              );
              onGoBack();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              side: BorderSide(color: context.appColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              context.tr('quiz_go_back'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
