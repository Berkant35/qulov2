import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

class PowerPurchaseSheet extends ConsumerStatefulWidget {
  const PowerPurchaseSheet({super.key});

  @override
  ConsumerState<PowerPurchaseSheet> createState() => _PowerPurchaseSheetState();
}

class _PowerPurchaseSheetState extends ConsumerState<PowerPurchaseSheet> {
  String? _buyingKey; // e.g. 'ORACLE_PURPLE'

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(diamondProvider.notifier).fetchBalance();
      ref.read(exchangeProvider.notifier).fetchAll();
    });
  }

  Future<void> _onBuy(String powerName, String diamondType) async {
    final key = '${powerName}_$diamondType';
    if (_buyingKey != null) return;
    setState(() => _buyingKey = key);

    final result = await ref
        .read(exchangeProvider.notifier)
        .buyPower(powerName, diamondType, 1);

    if (!mounted) return;

    result.when(
      success: (_) {
        Navigator.of(context).pop();
      },
      failure: (f) {
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          Navigator.of(context).pop();
          PaywallBottomSheetContent.show(ref, trigger: 'power_purchase');
          return;
        }
        final message = f.message ?? context.tr('purchase_failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
    setState(() => _buyingKey = null);
  }

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
                  borderRadius: BorderRadius.circular(2),
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
              data: (bal) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DiamondIcon.green(size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${bal.green}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  const DiamondIcon.purple(size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${bal.purple}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: AppLoadingWidget.small()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Power list
            if (exchange.isLoading)
              const Center(child: AppLoadingWidget.large())
            else if (exchange.rates != null)
              ...exchange.rates!.powers.map(
                (power) => _PowerRow(
                  power: power,
                  inventoryCount: exchange.getCount(power.name),
                  buyingKey: _buyingKey,
                  onBuy: _onBuy,
                ),
              ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _PowerRow extends StatelessWidget {
  final ExchangeRatePower power;
  final int inventoryCount;
  final String? buyingKey;
  final Future<void> Function(String powerName, String diamondType) onBuy;

  const _PowerRow({
    required this.power,
    required this.inventoryCount,
    required this.buyingKey,
    required this.onBuy,
  });

  String _powerLabel(BuildContext context) {
    final key = switch (power.name) {
      'ORACLE' => 'power_oracle',
      'HALF' => 'power_half',
      'SKIP' => 'power_skip',
      'SKIP_ALL' => 'power_skip_all',
      'TIME_EXTEND' => 'power_time',
      'HINT' => 'power_hint',
      _ => power.name,
    };
    return context.tr(key);
  }

  String _powerDesc(BuildContext context) {
    final key = switch (power.name) {
      'ORACLE' => 'power_oracle_desc',
      'HALF' => 'power_half_desc',
      'SKIP' => 'power_skip_desc',
      'SKIP_ALL' => 'power_skip_all_desc',
      'TIME_EXTEND' => 'power_time_extend_desc',
      'HINT' => 'power_hint_desc',
      _ => '',
    };
    return key.isEmpty ? '' : context.tr(key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerType = PowerType.fromApiName(power.name);
    if (powerType == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            PowerIcon(
              type: powerType,
              size: 28,
              showCount: inventoryCount > 0,
              count: inventoryCount,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _powerLabel(context),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _powerDesc(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Purple buy button
            _BuyChip(
              cost: power.purpleCost,
              icon: const DiamondIcon.purple(size: 14, showGlow: false),
              isLoading: buyingKey == '${power.name}_PURPLE',
              onTap: () => onBuy(power.name, 'PURPLE'),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Green buy button
            _BuyChip(
              cost: power.greenCost,
              icon: const DiamondIcon.green(size: 14, showGlow: false),
              isLoading: buyingKey == '${power.name}_GREEN',
              onTap: () => onBuy(power.name, 'GREEN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyChip extends StatelessWidget {
  final int cost;
  final Widget icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _BuyChip({
    required this.cost,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 36,
                height: 18,
                child: Center(child: AppLoadingWidget.small()),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
