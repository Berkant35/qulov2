import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';

/// Rainbow alanları qulo-server `user.service.getMe`'den gelir (Plan 1–2). Eski sunucu/
/// eksik alan çökertmez: bakiye 0, bayraklar kapalı (Rainbow hiçbir yüzeyde görünmez).
void main() {
  const base = {'id': 'u1', 'email': 'u1@qulo.test'};

  group('UserModel — Rainbow alanları', () {
    test('alanlar yoksa 0 / false / false', () {
      final user = UserModel.fromJson(base);
      expect(user.rainbowDiamonds, 0);
      expect(user.rainbowEnabled, isFalse);
      expect(user.hasRewardRedemptions, isFalse);
    });

    test('null gelirse de 0 / false / false', () {
      final user = UserModel.fromJson({
        ...base,
        'rainbow_diamonds': null,
        'rainbow_enabled': null,
        'has_reward_redemptions': null,
      });
      expect(user.rainbowDiamonds, 0);
      expect(user.rainbowEnabled, isFalse);
      expect(user.hasRewardRedemptions, isFalse);
    });

    test('dolu alanlar parse edilir ve toJson ile geri döner', () {
      final user = UserModel.fromJson({
        ...base,
        'rainbow_diamonds': 42,
        'rainbow_enabled': true,
        'has_reward_redemptions': true,
      });
      expect(user.rainbowDiamonds, 42);
      expect(user.rainbowEnabled, isTrue);
      expect(user.hasRewardRedemptions, isTrue);
      expect(UserModel.fromJson(user.toJson()), user);
    });
  });

  group('UserModel.withBalances', () {
    test('üç bakiyeyi yazar, diğer alanlara dokunmaz', () {
      final user = UserModel.fromJson({
        ...base,
        'name': 'Ada',
        'green_diamonds': 5,
        'purple_diamonds': 9,
        'rainbow_diamonds': 1,
        'rainbow_enabled': true,
      });

      final updated = user.withBalances(const DiamondBalance(green: 7, purple: 3, rainbow: 12));

      expect(updated.greenDiamonds, 7);
      expect(updated.purpleDiamonds, 3);
      expect(updated.rainbowDiamonds, 12);
      expect(updated.name, 'Ada');
      expect(updated.rainbowEnabled, isTrue);
      expect(updated.email, 'u1@qulo.test');
    });
  });
}
