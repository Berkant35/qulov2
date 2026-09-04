import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/providers/store_prices_provider.dart';

/// Fiyat koda gomulu degil: magazadan gelir; magaza yoksa bos map (asla USD literal).
void main() {
  test('loader sonucu productId → fiyat metni', () async {
    final c = ProviderContainer(overrides: [
      storePricesLoaderProvider.overrideWithValue(() async => {'qulopurple50': '₺39,99'}),
    ]);
    addTearDown(c.dispose);
    expect(await c.read(storePricesProvider.future), {'qulopurple50': '₺39,99'});
  });

  test('loader patlarsa boş map', () async {
    final c = ProviderContainer(overrides: [
      storePricesLoaderProvider.overrideWithValue(() async => throw Exception('rc')),
    ]);
    addTearDown(c.dispose);
    expect(await c.read(storePricesProvider.future), isEmpty);
  });
}
