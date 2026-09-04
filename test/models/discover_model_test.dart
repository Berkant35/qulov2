import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/discover_model.dart';

/// Discover kartı mesafesi de nullable: sunucu hesaplayamazsa null, 0 değil
/// (0 → "yakında" yanılgısı). Public profile modeliyle aynı sözleşme.
void main() {
  group('ProfileCardModel.distanceKm', () {
    test('sayı gelirse double', () {
      final c = ProfileCardModel.fromJson(_baseJson()..['distance_km'] = 3.2);
      expect(c.distanceKm, 3.2);
    });

    test('null gelirse null kalır', () {
      final c = ProfileCardModel.fromJson(_baseJson()..['distance_km'] = null);
      expect(c.distanceKm, isNull);
    });
  });
}

Map<String, dynamic> _baseJson() => {
      'user_id': 'u2',
      'name': 'Ada',
      'question_count': 3,
      'profile_completion': 80,
      'is_boosted': false,
    };
