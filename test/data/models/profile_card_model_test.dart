import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/discover_model.dart';

void main() {
  group('ProfileCardModel.fromJson', () {
    test('distance_tier okunur', () {
      final card = ProfileCardModel.fromJson({
        'user_id': 'u1',
        'question_count': 2,
        'distance_km': 340.5,
        'distance_tier': 2,
      });

      expect(card.distanceTier, 2);
      expect(card.distanceKm, 340.5);
    });

    test('distance_tier yoksa 0 varsayilir — eski sunucuya karsi guvenli', () {
      final card = ProfileCardModel.fromJson({
        'user_id': 'u1',
        'question_count': 2,
      });

      expect(card.distanceTier, 0);
    });

    test('distance_km null kalabilir — 0 "yakinda" demek DEGIL', () {
      final card = ProfileCardModel.fromJson({
        'user_id': 'u1',
        'question_count': 2,
        'distance_tier': 0,
      });

      expect(card.distanceKm, isNull);
    });
  });
}
