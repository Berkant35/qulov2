import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/diamond_reason_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/features/performance/mixins/diamond_transaction_tile_mixin.dart';

class DiamondTransactionTile extends StatelessWidget with DiamondTransactionTileMixin {
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
                  context.tr(diamondReasonKey(transaction.reason)),
                  style: theme.textTheme.bodyMedium,
                ),
                if (transaction.createdAt != null)
                  Text(
                    formattedDate(context, transaction.createdAt!),
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
}
