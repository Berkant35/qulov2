import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/transaction_tile.dart';

class DiamondsTransactionHistory extends StatelessWidget {
  final List<DiamondTransaction> history;
  final bool isLoading;
  final VoidCallback onSeeAll;

  const DiamondsTransactionHistory({
    super.key,
    required this.history,
    required this.isLoading,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('history'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (history.length > 5)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  context.tr('see_all'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.appColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const Center(child: AppLoadingWidget.large())
        else if (history.isEmpty)
          Text(
            context.tr('no_transactions'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          )
        else
          ...history.take(5).map(
                (tx) => TransactionTile(transaction: tx),
              ),
      ],
    );
  }
}
