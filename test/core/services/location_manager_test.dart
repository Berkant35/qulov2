import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:qulo_v2/core/services/location_manager.dart';

/// Konumdan ulke kodu (2026-09-23): `users.country` tum uygulama kullanicilarinda
/// NULL kaliyordu, `isoCountryCode` burada dusuruluyordu. Sunucu `^[A-Z]{2}$`
/// bekler; normalizasyon tek yerde.
void main() {
  group('LocationManager.placeInfoFrom', () {
    test('ISO-2 kod oldugu gibi, sehir locality', () {
      final info = LocationManager.placeInfoFrom(
        const Placemark(locality: 'Istanbul', administrativeArea: 'Istanbul', isoCountryCode: 'TR'),
      );
      expect(info, (city: 'Istanbul', countryCode: 'TR'));
    });

    test('kucuk harf ve bosluk normalize edilir', () {
      expect(LocationManager.placeInfoFrom(const Placemark(isoCountryCode: ' tr ')).countryCode, 'TR');
    });

    test('iki harf degilse null — sunucu reddetmesin diye hic gonderilmez', () {
      expect(LocationManager.placeInfoFrom(const Placemark(isoCountryCode: 'TUR')).countryCode, isNull);
      expect(LocationManager.placeInfoFrom(const Placemark(isoCountryCode: '')).countryCode, isNull);
      expect(LocationManager.placeInfoFrom(const Placemark()).countryCode, isNull);
    });

    test('locality yoksa administrativeArea sehir olur (mevcut davranis)', () {
      expect(LocationManager.placeInfoFrom(const Placemark(administrativeArea: 'Bangkok')).city, 'Bangkok');
    });
  });
}
