import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';

/// İlk quiz ikinci şansı (sunucu `free_second_chance`): yanlış cevaptan sonra
/// bu soruyu bedava geçme kartı. Metin ve "ÜCRETSİZ" rozeti bilerek bağırıyor —
/// eski veride ücretsiz SKIP'i kimse kullanmadı; bedava olduğu fark edilmeliydi.
class FreeSecondChanceCard extends StatelessWidget {
  const FreeSecondChanceCard({super.key, required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = context.appColors.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: success.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('quiz_second_chance_title'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _FreeBadge(color: success),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('quiz_second_chance_body'),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          SafeTapButton(
            onTap: onTap,
            builder: (context, isLoading, safeTap) => AppButton(
              label: context.tr('quiz_second_chance_cta'),
              isLoading: isLoading,
              onPressed: safeTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          context.tr('quiz_second_chance_free_badge'),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkOnDark,
                fontWeight: FontWeight.w800,
              ),
        ),
      );
}
