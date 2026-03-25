import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';

class DiamondTransactionTile extends StatelessWidget {
  final DiamondTransaction transaction;

  const DiamondTransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGreen = transaction.type == 'GREEN';
    final isPositive = transaction.amount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          isGreen
              ? const DiamondIcon.green(size: 20, showGlow: false)
              : const DiamondIcon.purple(size: 20, showGlow: false),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reasonLabel(context, transaction.reason),
                  style: theme.textTheme.bodyMedium,
                ),
                if (transaction.createdAt != null)
                  Text(
                    _formatDate(transaction.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.amount}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? context.appColors.secondary
                  : context.appColors.error,
            ),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(BuildContext context, String reason) {
    return switch (reason) {
      'POWER_USED' => context.tr('reason_power_used'),
      'POWER_REWARD' => context.tr('reason_power_reward'),
      'IAP' => context.tr('reason_iap'),
      'REFERRAL' => context.tr('reason_referral'),
      'SUBSCRIPTION_BONUS' => context.tr('reason_subscription'),
      'BOOST' => context.tr('reason_boost'),
      _ => reason.replaceAll('_', ' ').toLowerCase(),
    };
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
