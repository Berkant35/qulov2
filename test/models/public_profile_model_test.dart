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
}

Map<String, dynamic> _baseJson() => {'user_id': 'u2', 'name': 'Ada', 'photos': <String>[]};
