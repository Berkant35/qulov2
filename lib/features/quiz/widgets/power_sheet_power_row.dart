import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/inventory_pulse.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/power_price_buttons.dart';
import 'package:qulo_v2/core/widgets/power_quantity_stepper.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';

/// Güç satın alma sayfasındaki tek güç satırı: ikon + envanter pulse'ı ([InventoryPulse]),
/// etiket/açıklama ve adet seçici; altında sona hizalı fiyat butonları (mor/yeşil/Rainbow).
/// `PowerPurchaseSheet`'ten taşındı (dosya boyutu kuralı) — davranış aynı kaldı.
class PowerSheetPowerRow extends StatefulWidget {
  final ExchangeRatePower power;
  final int inventoryCount;
  final DiamondType? loadingType;
  final Future<void> Function(String powerName, DiamondType type, int quantity) onBuy;

  const PowerSheetPowerRow({
    super.key,
    required this.power,
    required this.inventoryCount,
    required this.loadingType,
    required this.onBuy,
  });

  @override
  State<PowerSheetPowerRow> createState() => _PowerSheetPowerRowState();
}

class _PowerSheetPowerRowState extends State<PowerSheetPowerRow> {
  int _quantity = powerPurchaseMinQuantity;

  String _powerLabel(BuildContext context) =>
      context.tr(powerLabelKey(widget.power.name));

  String _powerDesc(BuildContext context) =>
      context.tr(powerDescKey(widget.power.name));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final powerType = PowerType.fromApiName(widget.power.name);
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
        // İki satır: Rainbow açıkken üç fiyat çipi etiketle aynı satırda dar telefona
        // sığmıyordu (360dp + %130 yazıda etiket sütunu 0 px'e eziliyor, satır
        // taşıyordu). Çipler artık kendi satırında, sona hizalı.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                InventoryPulse(
                  count: widget.inventoryCount,
                  glowColor: powerType.color,
                  child: PowerIcon(
                    type: powerType,
                    size: 28,
                    showCount: widget.inventoryCount > 0,
                    count: widget.inventoryCount,
                  ),
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
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _powerDesc(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PowerQuantityStepper(
                  quantity: _quantity,
                  onChanged: (q) => setState(() => _quantity = q),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            PowerPriceButtons(
              power: widget.power,
              quantity: _quantity,
              loadingType: widget.loadingType,
              onBuy: (type) => widget.onBuy(widget.power.name, type, _quantity),
              direction: Axis.horizontal,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
