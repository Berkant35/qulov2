import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/diamond_reason_labels.dart';

/// Elmas gecmisi satirinda kullaniciya ic kod (`PROFILE_COMPLETION`,
/// `POWER_USED:HALF`) gosterilmez. Eskiden elmas ekrani sebebi ham basiyordu;
/// performans ekrani tam eslesme ariyordu (`'POWER_USED'`, `'IAP'`) ve
/// prod'daki ek almis sebeplerin neredeyse hicbirini tutmuyordu.
void main() {
  group('prod\'daki gercek sebepler (2026-09-11, 292 satir, 18 deger)', () {
    // Kaynak: `select type, reason, count(*) from diamond_transactions group by ...`
    const prod = {
      'POWER_REWARD:ORACLE': 'reason_power_reward',
      'POWER_REWARD:HALF': 'reason_power_reward',
      'POWER_REWARD:SKIP_RESCUE': 'reason_power_reward',
      'POWER_REWARD:SKIP': 'reason_power_reward',
      'POWER_REWARD:TIME_EXTEND': 'reason_power_reward',
      'CHAT_QUESTION_POWER_REWARD': 'reason_power_reward',
      'CHAT_QUESTION_REWARD': 'reason_question_reward',
      'PROFILE_COMPLETION': 'reason_profile_completion',
      'POWER_USED:ORACLE': 'reason_power_used',
      'POWER_USED:HALF': 'reason_power_used',
      'BADGE_SILVER': 'reason_badge',
      'POWER_USED:SKIP_RESCUE': 'reason_power_used',
      'SUBSCRIPTION_BONUS': 'reason_subscription',
      'POWER_USED:SKIP': 'reason_power_used',
      'IAP_PURCHASE': 'reason_iap',
      'BADGE_GOLD': 'reason_badge',
      'chat_question_power_block': 'reason_power_used',
      'POWER_USED:TIME_EXTEND': 'reason_power_used',
    };

    for (final MapEntry(key: reason, value: expected) in prod.entries) {
      test('$reason → $expected', () {
        expect(diamondReasonKey(reason), expected);
      });
    }

    test('hicbir prod sebebi genel etikete dusmez', () {
      expect(prod.keys.map(diamondReasonKey), isNot(contains('reason_other')));
    });
  });

  group('sunucunun henuz prod\'da satiri olmayan sebepleri', () {
    const serverOnly = {
      'REFERRAL_REWARD_REFEREE': 'reason_referral',
      'REFERRAL_REWARD_REFERRER': 'reason_referral',
      'BOOST': 'reason_boost',
      'exchange_green_to_purple': 'reason_exchange',
      'buy_power_HINT': 'reason_power_purchase',
      'RETENTION_BONUS': 'reason_retention',
      'BADGE_BRONZE': 'reason_badge',
      'chat_question_skip': 'reason_power_used',
      'chat_question_rescue': 'reason_power_used',
      'chat_question_power_unblock': 'reason_power_used',
      'chat_question_power_oracle': 'reason_power_used',
    };

    for (final MapEntry(key: reason, value: expected) in serverOnly.entries) {
      test('$reason → $expected', () {
        expect(diamondReasonKey(reason), expected);
      });
    }
  });

  test('bilinmeyen sebep ham kod degil genel etiket olur', () {
    expect(diamondReasonKey('SOMETHING_NEW'), 'reason_other');
    expect(diamondReasonKey(''), 'reason_other');
    // Odul/harcama ayrimi onekle yapilmaz: bilinmeyen sohbet sebebi harcama sayilmaz.
    expect(diamondReasonKey('chat_question_answered'), 'reason_other');
  });

  test('uretilen her anahtar listede — dinamik anahtar testi hepsini kapsar', () {
    const samples = [
      'POWER_USED:HALF', 'POWER_REWARD:ORACLE', 'CHAT_QUESTION_REWARD', 'buy_power_HINT',
      'IAP_PURCHASE', 'REFERRAL_REWARD_REFEREE', 'SUBSCRIPTION_BONUS', 'BOOST',
      'PROFILE_COMPLETION', 'BADGE_GOLD', 'exchange_green_to_purple', 'RETENTION_BONUS', 'x',
    ];

    expect(samples.map(diamondReasonKey).toSet(), diamondReasonKeys.toSet());
  });

  test('diamondTypeKey — GREEN yesil, PURPLE mor', () {
    expect(diamondTypeKey('GREEN'), 'green_diamonds');
    expect(diamondTypeKey('PURPLE'), 'purple_diamonds');
  });
}
