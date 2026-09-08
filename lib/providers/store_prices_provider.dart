import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/features/diamonds/models/diamond_tier.dart';

/// productId → magazanin yerel fiyat metni (`storeProduct.priceString`).
typedef StorePricesLoader = Future<Map<String, String>> Function();

/// Uygulamanin satin alabildigi TUM urun kimlikleri — fiyat sorgusunun kapsami
/// bu listedir. Satin alma yollari (`purchaseByProductId`) ayni kimlikleri
/// kullanir; liste tek yerde durdugu icin ikisi ayrisamaz.
List<String> get purchasableProductIds => [
      ...DiamondTier.values.map((tier) => tier.productId),
      ...RevenueCatService.subscriptionProductIds,
    ];

Future<Map<String, String>> loadStorePricesFromRevenueCat() =>
    RevenueCatService.getPrices(purchasableProductIds);

/// Testte override edilir; uretimde RevenueCat.
final storePricesLoaderProvider =
    Provider<StorePricesLoader>((_) => loadStorePricesFromRevenueCat);

/// Fiyat koda gomulu DEGIL: magaza yoksa bos map, ekran `—` gosterir.
/// `autoDispose` + kosullu `keepAlive`: bos sonuc (magaza henuz hazir degil)
/// kalici cache'lenmez — dinleyicisiz kalinca dusurulur ve bir sonraki
/// okumada tekrar denenir. Dolu sonuc `keepAlive()` ile oturum boyunca sabit kalir.
final storePricesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  Map<String, String> prices;
  try {
    prices = await ref.read(storePricesLoaderProvider)();
  } catch (_) {
    prices = const {};
  }
  if (prices.isNotEmpty) {
    ref.keepAlive();
  }
  return prices;
});
