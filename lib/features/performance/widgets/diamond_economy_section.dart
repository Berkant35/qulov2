import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/features/performance/widgets/diamond_transaction_tile.dart';

class DiamondEconomySection extends StatelessWidget {
  final int greenBalance;
  final int purpleBalance;
  final List<DiamondTransaction> recentTransactions;
  final VoidCallback onViewAll;

  const DiamondEconomySection({
    super.key,
    required this.greenBalance,
    required this.purpleBalance,
    required this.recentTransactions,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('diamond_economy'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _BalanceChip(
                icon: const DiamondIcon.green(size: 18),
                value: greenBalance,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _BalanceChip(
                icon: const DiamondIcon.purple(size: 18),
                value: purpleBalance,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('recent_transactions'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recentTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                context.tr('no_transactions'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          )
        else ...[
          ...recentTransactions.take(10).map(
                (t) => DiamondTransactionTile(transaction: t),
              ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AppButton(
              label: context.tr('view_all'),
              variant: AppButtonVariant.text,
              fullWidth: false,
              onPressed: onViewAll,
            ),
          ),
        ],
      ],
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final Widget icon;
  final int value;

  const _BalanceChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
