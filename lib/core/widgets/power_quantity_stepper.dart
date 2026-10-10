import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Güç satın almada adet seçici. Sınırlar sunucunun kabul ettiği aralık:
/// [powerPurchaseMinQuantity]–[powerPurchaseMaxQuantity] (`power_purchase.dart`).
/// Exchange kartı ve Quiz satın alma sayfası ortak kullanır.
class PowerQuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const PowerQuantityStepper({
    super.key,
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
          PowerQuantityStepperButton(
            icon: Icons.remove,
            enabled: quantity > powerPurchaseMinQuantity,
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
          PowerQuantityStepperButton(
            icon: Icons.add,
            enabled: quantity < powerPurchaseMaxQuantity,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class PowerQuantityStepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const PowerQuantityStepperButton({
    super.key,
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
        padding: const EdgeInsets.all(AppSpacing.xs),
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
