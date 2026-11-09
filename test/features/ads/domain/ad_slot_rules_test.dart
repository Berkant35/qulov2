import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/ads/domain/ad_audience.dart';
import 'package:qulo_v2/features/ads/domain/ad_slot_rules.dart';

/// Reklam yerleşim kuralı (saf Dart): her 5 profilde bir yuva, ilk reklam en
/// erken 4 profil sonra, oturumda en çok 6, VIP/bilinmeyende asla.
void main() {
  const rules = AdSlotRules();

  group('sabitler', () {
    test('kararlaştırılan değerler', () {
      expect(AdSlotConstants.profilesPerSlot, 5);
      expect(AdSlotConstants.minProfilesBeforeFirstAd, 4);
      expect(AdSlotConstants.maxAdsPerSession, 6);
    });
  });

  group('yuva eşiği', () {
    test('yuvalar 5, 10, 15, ... profilden sonra', () {
      expect([for (var i = 0; i < 4; i++) rules.thresholdFor(i)], [5, 10, 15, 20]);
    });

    test('ilk reklam, profilesPerSlot küçük olsa bile en az 4 profil sonra', () {
      const tight = AdSlotRules(profilesPerSlot: 2);
      expect(tight.thresholdFor(0), 4);
      expect(tight.thresholdFor(1), 6);
    });
  });

  group('isSlotDue', () {
    bool due(int passed, {int resolved = 0, int shown = 0, bool next = true}) => rules.isSlotDue(
          profilesPassed: passed,
          slotsResolved: resolved,
          adsShown: shown,
          hasNextCard: next,
        );

    test('4 profilde henüz değil, 5\'te geldi', () {
      expect(due(4), isFalse);
      expect(due(5), isTrue);
    });

    test('ilk yuva çözüldükten sonra bir sonraki 10. profilde', () {
      expect(due(7, resolved: 1, shown: 1), isFalse);
      expect(due(10, resolved: 1, shown: 1), isTrue);
    });

    test('oturum başına en çok 6 reklam', () {
      expect(due(30, resolved: 5, shown: 5), isTrue);
      expect(due(35, resolved: 6, shown: 6), isFalse);
      expect(due(1000, resolved: 6, shown: 6), isFalse);
    });

    test('boş desteye (sonraki kart yok) reklam konmaz', () {
      expect(due(5, next: false), isFalse);
    });

    test('boş liste / hiç profil geçilmemiş: reklam yok', () {
      expect(due(0), isFalse);
      expect(due(0, next: false), isFalse);
    });
  });

  group('shouldPreload', () {
    bool preload(int passed, {int resolved = 0, int shown = 0}) =>
        rules.shouldPreload(profilesPassed: passed, slotsResolved: resolved, adsShown: shown);

    test('yuvadan 2 profil önce başlar', () {
      expect(preload(2), isFalse);
      expect(preload(3), isTrue);
    });

    test('üst sınırda yüklenmez', () {
      expect(preload(100, resolved: 6, shown: 6), isFalse);
    });
  });

  group('mayServe', () {
    test('yalnız doğrulanmış ücretsiz kullanıcı + uzaktan açık', () {
      bool may(AdAudience a, {bool remote = true}) =>
          rules.mayServe(audience: a, remoteEnabled: remote);

      expect(may(AdAudience.free), isTrue);
      expect(may(AdAudience.vip), isFalse);
      expect(may(AdAudience.unknown), isFalse); // fail-closed
      expect(may(AdAudience.free, remote: false), isFalse);
    });
  });
}
