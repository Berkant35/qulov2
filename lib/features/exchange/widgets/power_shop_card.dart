import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/inventory_pulse.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/power_price_buttons.dart';
import 'package:qulo_v2/core/widgets/power_quantity_stepper.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/features/exchange/mixins/power_shop_card_mixin.dart';

class PowerShopCard extends ConsumerStatefulWidget {
  final ExchangeRatePower power;
  final int inventoryCount;

  const PowerShopCard({
    super.key,
    required this.power,
    required this.inventoryCount,
  });

  @override
  ConsumerState<PowerShopCard> createState() => _PowerShopCardState();
}

class _PowerShopCardState extends ConsumerState<PowerShopCard>
    with PowerShopCardMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Power icon with inventory badge
          InventoryPulse(
            count: widget.inventoryCount,
            glowColor: powerType.color,
            child: PowerIcon(
              type: powerType,
              size: 32,
              showCount: widget.inventoryCount > 0,
              count: widget.inventoryCount,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  powerLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  powerDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Quantity stepper
          PowerQuantityStepper(
            quantity: quantity,
            onChanged: (q) => setState(() => quantity = q),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Buy buttons (mor, yeşil, Rainbow yalnız sunucu açtıysa)
          PowerPriceButtons(
            power: widget.power,
            quantity: quantity,
            loadingType: buyingWith,
            onBuy: onBuy,
          ),
        ],
      ),
    );
  }
}
