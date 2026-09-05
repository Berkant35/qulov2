import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/exchange/mixins/power_shop_card_mixin.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';

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
    with SingleTickerProviderStateMixin, PowerShopCardMixin {
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
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: pulseController.isAnimating
                      ? [
                          BoxShadow(
                            color: powerType.color
                                .withValues(alpha: glowAnimation.value),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Transform.scale(
                  scale: scaleAnimation.value,
                  child: child,
                ),
              );
            },
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
                const SizedBox(height: 2),
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
          _QuantityStepper(
            quantity: quantity,
            onChanged: (q) => setState(() => quantity = q),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Buy buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Purple cost button
              _BuyButton(
                cost: widget.power.purpleCost * quantity,
                icon: const DiamondIcon.purple(size: 16, showGlow: false),
                isLoading: buyingWith == 'purple',
                onTap: () => onBuy('purple'),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Green cost button
              _BuyButton(
                cost: widget.power.greenCost * quantity,
                icon: const DiamondIcon.green(size: 16, showGlow: false),
                isLoading: buyingWith == 'green',
                onTap: () => onBuy('green'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            enabled: quantity > 1,
            onTap: () => onChanged(quantity - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            enabled: quantity < 99,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? context.appColors.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final int cost;
  final Widget icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _BuyButton({
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
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 48,
                height: 20,
                child: Center(child: AppLoadingWidget.small()),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$cost',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
