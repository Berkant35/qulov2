import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/revenuecat_service.dart';
import 'package:qulo_v2/features/diamonds/utils/monthly_price_label.dart';

void main() {
  test('planPriceLabels: iki planın aylık etiketi, eksik olan null', () {
    final labels = planPriceLabels(
      prices: {RevenueCatService.plusProductId: '\$4.99'},
      periodSuffix: '/mo',
    );
    expect(labels.plus, '\$4.99/mo');
    expect(labels.premium, isNull);
  });

  test('planPriceLabels: fiyat haritası boşsa ikisi de null', () {
    final labels = planPriceLabels(prices: const {}, periodSuffix: '/mo');
    expect(labels.plus, isNull);
    expect(labels.premium, isNull);
  });
}
