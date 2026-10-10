import 'package:qulo_v2/core/constants/diamond_type.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';

/// Tek alımda seçilebilecek adet sınırları — sunucuyla aynı olmalı:
/// qulo-server `src/validators/exchange.validator.ts:20` →
/// `quantity: z.number().int().min(1).max(50)`. Sınır dışı adet 400 VALIDATION_ERROR döner.
const powerPurchaseMinQuantity = 1;
const powerPurchaseMaxQuantity = 50;

/// Güç satın almada sunulan elmas türleri. Rainbow yalnız sunucu açtıysa
/// (`UserModel.rainbowEnabled`) — spec 2026-09-27 §2.5.
List<DiamondType> powerPurchaseTypes({required bool rainbowEnabled}) => [
      DiamondType.purple,
      DiamondType.green,
      if (rainbowEnabled) DiamondType.rainbow,
    ];

/// Toplam fiyat. Rainbow'un fiyatı yeşil fiyatıdır (qulo-server `exchange.service`:
/// RAINBOW → `powerCosts[X].greenCost`).
int powerPrice(ExchangeRatePower power, DiamondType type, int quantity) => switch (type) {
      DiamondType.purple => power.purpleCost * quantity,
      DiamondType.green || DiamondType.rainbow => power.greenCost * quantity,
    };

/// Güç satın alma hatasının sınıfı. İki ekran (Exchange kartı, Quiz satın alma sayfası)
/// aynı sınıflamayı kullanır; tepkiyi (paywall, snackbar, bayrak yenileme) ekran seçer.
enum PowerPurchaseFailureKind { insufficient, rainbowUnavailable, cooldown, other }

PowerPurchaseFailureKind classifyPowerPurchaseFailure(String? serverCode) =>
    switch (serverCode) {
      'INSUFFICIENT_DIAMONDS' => PowerPurchaseFailureKind.insufficient,
      'RAINBOW_NOT_AVAILABLE' => PowerPurchaseFailureKind.rainbowUnavailable,
      'DIAMOND_COOLDOWN' => PowerPurchaseFailureKind.cooldown,
      _ => PowerPurchaseFailureKind.other,
    };
