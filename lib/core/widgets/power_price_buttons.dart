import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/power_purchase.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_buy_button.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/providers/rainbow_flag.dart';

/// Bir gücün fiyat butonları: mor, yeşil ve — yalnız sunucu açtıysa — Rainbow.
/// Hangi türlerin sunulduğu ve fiyatlar `power_purchase.dart`'tan (tek kaynak).
/// [direction]: dikey sütun (Exchange kartı) ya da yatay, sona hizalı ve sığmazsa
/// alt satıra kayan dizi (Quiz satın alma sayfası).
class PowerPriceButtons extends ConsumerWidget {
  final ExchangeRatePower power;
  final int quantity;

  /// Sürmekte olan satın almanın türü (null = yok).
  final DiamondType? loadingType;
  final ValueChanged<DiamondType> onBuy;
  final Axis direction;
  final bool dense;

  const PowerPriceButtons({
    super.key,
    required this.power,
    required this.quantity,
    required this.loadingType,
    required this.onBuy,
    this.direction = Axis.vertical,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rainbowEnabled = ref.watchRainbowEnabled();

    final buttons = [
      for (final type in powerPurchaseTypes(rainbowEnabled: rainbowEnabled))
        DiamondBuyButton(
          cost: powerPrice(power, type, quantity),
          type: type,
          isLoading: loadingType == type,
          onTap: () => onBuy(type),
          dense: dense,
        ),
    ];

    if (direction == Axis.vertical) {
      return Column(mainAxisSize: MainAxisSize.min, spacing: AppSpacing.xs, children: buttons);
    }
    // Yatay (Quiz satın alma sayfası): dar ekranda sığmayan çip alt satıra kayar, taşmaz
    // (sunucu sınırında 500 × 50 = 25000 fiyat + %130 yazı 360dp'ye sığmıyor).
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: buttons,
    );
  }
}
