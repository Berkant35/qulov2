import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';

/// Abonelik durumu — ucretli ozellik kapilari (pasaport, geri alma, reklam,
/// soru slotu) `isPlus` / `isPremium` / `isFree`'ye bakiyor (8 ekran).
///
/// Sunucu sozlesmesi (qulo-server `subscription.controller.ts` →
/// `getSubscriptionStatusHandler`): `{subscription: {plan, status, expiresAt,
/// isActive}, limits}`. `isActive` sunucuda `expiresAt > now` ile hesaplanir;
/// suresi dolunca `status: 'expired'`, `isActive: false`.
void main() {
  group('ucretli kapilar', () {
    test('aktif Plus yalnizca isPlus acar', () {
      const info = SubscriptionInfo(plan: 'plus', status: 'active', isActive: true);

      expect(info.isPlus, isTrue);
      expect(info.isPremium, isFalse);
      expect(info.isFree, isFalse);
    });

    test('aktif Premium yalnizca isPremium acar', () {
      const info = SubscriptionInfo(plan: 'premium', status: 'active', isActive: true);

      expect(info.isPremium, isTrue);
      expect(info.isPlus, isFalse);
      expect(info.isFree, isFalse);
    });

    test('suresi dolmus Premium hicbir ucretli kapiyi acmaz', () {
      // Plan adi hala 'premium' — kapi plan adina degil isActive'e bakmali.
      const info = SubscriptionInfo(plan: 'premium', status: 'expired', isActive: false);

      expect(info.isPremium, isFalse);
      expect(info.isPlus, isFalse);
      expect(info.isFree, isTrue);
    });

    test('bilinmeyen plan adi Plus/Premium sayilmaz (aktif olsa bile)', () {
      const info = SubscriptionInfo(plan: 'gold', status: 'active', isActive: true);

      expect(info.isPlus, isFalse);
      expect(info.isPremium, isFalse);
    });

    test('free() hicbir ucretli kapiyi acmaz', () {
      final info = SubscriptionInfo.free();

      expect(info.isFree, isTrue);
      expect(info.isPlus, isFalse);
      expect(info.isPremium, isFalse);
    });
  });

  group('sunucu yaniti', () {
    test('status yanitinin subscription alani parse edilir', () {
      final response = SubscriptionStatusResponse.fromJson({
        'subscription': {
          'plan': 'premium',
          'status': 'active',
          'expiresAt': '2026-10-11T00:00:00.000Z',
          'isActive': true,
        },
        'limits': {'dailyDiscovers': 999999, 'maxQuestions': 10, 'dailyUndos': 999999},
      });

      expect(response.subscription.isPremium, isTrue);
      expect(response.subscription.expiresAt, '2026-10-11T00:00:00.000Z');
    });

    test('abonelik yok yaniti (null plan) free olur', () {
      final response = SubscriptionStatusResponse.fromJson({
        'subscription': {'plan': null, 'status': null, 'expiresAt': null, 'isActive': false},
        'limits': <String, dynamic>{},
      });

      expect(response.subscription.isFree, isTrue);
    });

    test('subscription alani yoksa free olur — cokmez', () {
      final response = SubscriptionStatusResponse.fromJson(<String, dynamic>{});

      expect(response.subscription, SubscriptionInfo.free());
    });

    test('isActive gelmezse aktif sayilmaz — kapi kapali kalir', () {
      final info = SubscriptionInfo.fromJson({'plan': 'plus', 'status': 'active'});

      expect(info.isPlus, isFalse);
    });
  });
}
