import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/discover_model.dart';

/// Discover karti → detay ekraninin on-yukleme profili
/// (`ProfileCardToPublicProfile`). Detay yuklenirken ekran bu profille dolar;
/// quiz hedefi de detay gelmemisse bu profilden alinir.
void main() {
  group('ProfileCardModel.toPublicProfile', () {
    test('kart alanlarini profile tasir', () {
      final card = ProfileCardModel(
        userId: 'u9',
        name: 'Ada',
        age: 27,
        city: 'Izmir',
        bio: 'Merhaba',
        photos: const ['p1', 'p2'],
        distanceKm: 3.5,
        questionCount: 4,
        profileCompletion: 80,
        isBoosted: true,
        relationshipGoal: 'SERIOUS',
        questionInfo: QuestionInfoModel(count: 4),
      );

      final p = card.toPublicProfile();

      expect(p.userId, 'u9');
      expect(p.name, 'Ada');
      expect(p.age, 27);
      expect(p.city, 'Izmir');
      expect(p.bio, 'Merhaba');
      expect(p.photos, ['p1', 'p2']);
      expect(p.distanceKm, 3.5);
      expect(p.profileCompletion, 80);
      expect(p.isBoosted, isTrue);
      expect(p.relationshipGoal, 'SERIOUS');
      expect(p.questionInfo?.count, 4);
      // Kartta olmayan alanlar uydurulmaz.
      expect(p.isOnline, isNull);
      expect(p.details, isNull);
    });

    test('foto listesi yoksa bos liste — galeri null ile patlamaz', () {
      const card = ProfileCardModel(userId: 'u1', questionCount: 2);

      expect(card.toPublicProfile().photos, isEmpty);
    });

    test('mesafe bilinmiyorsa null kalir — 0 "yakinda" demek degil', () {
      const card = ProfileCardModel(userId: 'u1', questionCount: 2);

      expect(card.toPublicProfile().distanceKm, isNull);
    });
  });
}
