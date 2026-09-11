import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';

/// Sunucu mesafeyi hesaplayamadığında `distance_km: null` gönderir; model bunu
/// 0'a çevirmemeli (0 → "yakında" yanılgısı).
void main() {
  group('PublicProfileModel.distanceKm', () {
    test('sayı gelirse double', () {
      final p = PublicProfileModel.fromJson(_baseJson()..['distance_km'] = 3.2);
      expect(p.distanceKm, 3.2);
    });

    test('null gelirse null kalır', () {
      final p = PublicProfileModel.fromJson(_baseJson()..['distance_km'] = null);
      expect(p.distanceKm, isNull);
    });

    test('alan yoksa null', () {
      final p = PublicProfileModel.fromJson(_baseJson());
      expect(p.distanceKm, isNull);
    });
  });

  group('gizlilik — baskasinin profili hassas alan TASIMAZ', () {
    // Sunucu `getPublicProfile` bunlari zaten gondermiyor (sunucu testi var);
    // bu test mobil modelin ileride bu alanlari yakalamaya baslamamasini
    // dondurur. Hassas alan modele eklenirse ya parse patlar (tip) ya da
    // toJson ciktisinda gorunur — ikisi de kirmizi.
    const sensitive = [
      'email', 'surname', 'lat', 'lng', 'phone', 'birth_date',
      'push_token', 'passport_lat', 'passport_lng', 'password_hash',
    ];

    test('sunucu yanitinda olsa bile modelde ve ciktisinda yok', () {
      final p = PublicProfileModel.fromJson({
        ..._baseJson(),
        for (final key in sensitive) key: 'SIZINTI',
        'details': {'job': 'Muhendis', 'email': 'SIZINTI'},
      });

      final top = p.toJson();
      final details = p.details!.toJson();
      for (final key in sensitive) {
        expect(top.containsKey(key), isFalse, reason: key);
      }
      expect(details.containsKey('email'), isFalse);
      expect('$top $details', isNot(contains('SIZINTI')));
      expect(details['job'], 'Muhendis', reason: 'senaryo: paylasilan detay tasiniyor');
    });
  });
}

Map<String, dynamic> _baseJson() => {'user_id': 'u2', 'name': 'Ada', 'photos': <String>[]};
