import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/providers/store_prices_provider.dart';

/// Uc ekranin (subscription_comparison_screen, paywall_bottom_sheet,
/// premium_suggestion_sheet) ortak "aylik abonelik fiyati" mantigi.
///
/// Fiyat RevenueCat'ten henuz gelmediyse (`prices[productId]` yok) null doner —
/// cagiran taraf bunu tek "fiyat bilinmiyor" sinyali olarak kullanir: hem buton
/// disabled olur hem etiket [unknownPriceLabel] fallback'ine duser (bkz. review I2).
String? monthlyPriceLabel({
  required Map<String, String> prices,
  required String productId,
  required String periodSuffix,
}) {
  final price = prices[productId];
  return price == null ? null : '$price$periodSuffix';
}

/// Fiyat bilinmedigi durumda gosterilen tek fallback etiketi — tum cagiran
/// taraflar `monthlyPriceLabel(...) ?? unknownPriceLabel` seklinde kullanir.
const unknownPriceLabel = '—';

/// Plus ve Premium'un aylik etiketleri; eksik fiyat null (buton disabled sinyali).
typedef PlanPriceLabels = ({String? plus, String? premium});

PlanPriceLabels planPriceLabels({
  required Map<String, String> prices,
  required String periodSuffix,
}) =>
    (
      plus: monthlyPriceLabel(
        prices: prices,
        productId: RevenueCatService.plusProductId,
        periodSuffix: periodSuffix,
      ),
      premium: monthlyPriceLabel(
        prices: prices,
        productId: RevenueCatService.premiumProductId,
        periodSuffix: periodSuffix,
      ),
    );

/// Uc ekranin ortak on-hazirligi: fiyat provider'ini izler, etiketleri uretir.
PlanPriceLabels watchPlanPriceLabels(BuildContext context, WidgetRef ref) =>
    planPriceLabels(
      prices: ref.watch(storePricesProvider).valueOrNull ?? const <String, String>{},
      periodSuffix: context.tr('sub_price_period_month'),
    );
