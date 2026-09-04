import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/utils/location_format.dart';

/// Mesafe/konum metni üç yerde gösteriliyor (discover kartı, profil detayı,
/// quiz başlığı); tek kaynaktan üretilir. Şehir yokken mesafe kaybolmamalı.
void main() {
  group('distanceLabel', () {
    test('1 km altı "yakında" etiketi', () {
      expect(distanceLabel(0.4, nearbyLabel: 'Yakında'), 'Yakında');
    });

    test('1 km ve üstü tek ondalıkla km', () {
      expect(distanceLabel(1.0, nearbyLabel: 'x'), '1.0 km');
      expect(distanceLabel(3.26, nearbyLabel: 'x'), '3.3 km');
    });
  });

  group('locationLine', () {
    test('şehir + mesafe', () {
      expect(
        locationLine(city: 'İstanbul', distanceKm: 3.2, nearbyLabel: 'x'),
        'İstanbul • 3.2 km',
      );
    });

    test('şehir yokken sadece mesafe — mesafe kaybolmaz', () {
      expect(locationLine(city: null, distanceKm: 3.2, nearbyLabel: 'x'), '3.2 km');
    });

    test('mesafe bilinmiyorken sadece şehir', () {
      expect(locationLine(city: 'İstanbul', distanceKm: null, nearbyLabel: 'x'), 'İstanbul');
    });

    test('ikisi de yoksa null — satır çizilmez', () {
      expect(locationLine(city: null, distanceKm: null, nearbyLabel: 'x'), isNull);
    });
  });
}
