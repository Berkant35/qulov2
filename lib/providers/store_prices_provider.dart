import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';

/// productId → magazanin yerel fiyat metni (`storeProduct.priceString`).
typedef StorePricesLoader = Future<Map<String, String>> Function();

Future<Map<String, String>> loadStorePricesFromRevenueCat() async {
  final offerings = await RevenueCatService.getOfferings();
  if (offerings == null) return const {};
  return {
    for (final offering in offerings.all.values)
      for (final package in offering.availablePackages)
        package.storeProduct.identifier: package.storeProduct.priceString,
  };
}

/// Testte override edilir; uretimde RevenueCat.
final storePricesLoaderProvider =
    Provider<StorePricesLoader>((_) => loadStorePricesFromRevenueCat);

/// Fiyat koda gomulu DEGIL: magaza yoksa bos map, ekran iskelet gosterir.
final storePricesProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    return await ref.read(storePricesLoaderProvider)();
  } catch (_) {
    return const {};
  }
});
