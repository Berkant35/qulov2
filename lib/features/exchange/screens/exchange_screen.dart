import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/features/diamonds/widgets/diamond_balance_card.dart';
import 'package:qulo_v2/features/exchange/widgets/convert_section.dart';
import 'package:qulo_v2/features/exchange/widgets/power_shop_card.dart';

class ExchangeScreen extends ConsumerStatefulWidget {
  const ExchangeScreen({super.key});

  @override
  ConsumerState<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends ConsumerState<ExchangeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(diamondProvider.notifier).fetchBalance();
      ref.read(exchangeProvider.notifier).fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(diamondProvider);
    final exchange = ref.watch(exchangeProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('exchange_title'),
      isLoading: exchange.isLoading,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Diamond Balance Card
            balance.when(
              data: (bal) => DiamondBalanceCard(
                greenCount: bal.green,
                purpleCount: bal.purple,
              ),
              loading: () =>
                  const Center(child: AppLoadingWidget.large()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.sectionGap),

            // 2. Convert Section
            const ConvertSection(),

            const SizedBox(height: AppSpacing.sectionGap),

            // 3. Power Shop Header
            Text(
              context.tr('exchange_powers_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Power Shop Cards
            if (exchange.rates != null)
              ...exchange.rates!.powers.map(
                (power) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PowerShopCard(
                    power: power,
                    inventoryCount:
                        exchange.getCount(power.name),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
