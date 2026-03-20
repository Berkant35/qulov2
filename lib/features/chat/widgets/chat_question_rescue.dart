import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

class ChatQuestionRescue extends StatelessWidget {
  final bool isPowerBlocked;
  final VoidCallback onSkip;
  final VoidCallback onPowerUnblock;
  final VoidCallback onGiveUp;

  const ChatQuestionRescue({
    super.key,
    required this.isPowerBlocked,
    required this.onSkip,
    required this.onPowerUnblock,
    required this.onGiveUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.appColors.error.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.timer_off_rounded,
                size: 32,
                color: context.appColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Süre Doldu!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cevap vermek için süren bitti. Güç kullanarak kurtulabilirsin.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            if (isPowerBlocked) ...[
              // Power block warning
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: context.appColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: context.appColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Güçler engellenmiş. Kilidi aç ve Geç gücünü kullan.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Power unblock button
              SafeTapButton(
                onTap: () async => onPowerUnblock(),
                builder: (context, isLoading, onTap) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: isLoading
                        ? const AppLoadingWidget.small()
                        : const Icon(Icons.lock_open, size: 20),
                    label: Text(AppLocalizations.of(context).get('chat_unlock')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.warning,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Skip button
              SafeTapButton(
                onTap: () async => onSkip(),
                builder: (context, isLoading, onTap) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: isLoading
                        ? const AppLoadingWidget.small()
                        : const Icon(Icons.skip_next_rounded, size: 22),
                    label: Text(AppLocalizations.of(context).get('chat_skip')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.info,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Give up button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onGiveUp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.textSecondary,
                  side: BorderSide(
                    color: context.appColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(AppLocalizations.of(context).get('chat_give_up')),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
