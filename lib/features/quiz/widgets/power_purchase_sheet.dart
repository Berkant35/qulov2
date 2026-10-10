import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/quiz/mixins/power_purchase_sheet_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/power_sheet_balance_row.dart';
import 'package:qulo_v2/features/quiz/widgets/power_sheet_power_row.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class PowerPurchaseSheet extends ConsumerStatefulWidget {
  const PowerPurchaseSheet({super.key});

  @override
  ConsumerState<PowerPurchaseSheet> createState() => _PowerPurchaseSheetState();
}

class _PowerPurchaseSheetState extends ConsumerState<PowerPurchaseSheet>
    with PowerPurchaseSheetMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exchange = ref.watch(exchangeProvider);
    final balance = ref.watch(diamondProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              context.tr('quiz_buy_power'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Diamond balance
            balance.when(
              data: (bal) => PowerSheetBalanceRow(balance: bal),
              loading: () => const Center(child: AppLoadingWidget.small()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Power list
            if (exchange.isLoading)
              const Center(child: AppLoadingWidget.large())
            else if (exchange.rates != null)
              ...exchange.rates!.powers.map(
                (power) => PowerSheetPowerRow(
                  power: power,
                  inventoryCount: exchange.getCount(power.name),
                  loadingType: buying?.power == power.name ? buying?.type : null,
                  onBuy: onBuy,
                ),
              ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
