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

  /// 2.0.18: kartta "Bugün / Bu hafta aktif" rozeti (sunucu yalnız kova gönderir).
  group('activity', () {
    Map<String, dynamic> card(Object? activity) => {'user_id': 'u1', 'question_count': 2, 'activity': activity};

    test('"today" ve "week" okunur', () {
      expect(ProfileCardModel.fromJson(card('today')).activity, CardActivity.today);
      expect(ProfileCardModel.fromJson(card('week')).activity, CardActivity.week);
    });

    test('null, eksik alan (eski sunucu) ve bilinmeyen değer → rozet yok, çökmez', () {
      expect(ProfileCardModel.fromJson(card(null)).activity, isNull);
      expect(ProfileCardModel.fromJson({'user_id': 'u1', 'question_count': 2}).activity, isNull);
      expect(ProfileCardModel.fromJson(card('month')).activity, isNull);
    });

    test('toJson geri yazar (undo önbelleği)', () {
      expect(ProfileCardModel.fromJson(card('week')).toJson()['activity'], 'week');
    });
  });
}
