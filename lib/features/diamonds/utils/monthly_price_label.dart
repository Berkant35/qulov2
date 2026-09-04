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
