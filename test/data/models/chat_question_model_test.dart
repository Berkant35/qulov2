import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';

/// qulo-server `chat-question.service`: güç ödülü yeşil + rainbow'a bölünür; yanıtlardaki
/// `green_reward` yeşil payı, yeni `rainbow_reward` ödenmiş mordan gelen payı taşır.
void main() {
  group('ChatQuestionAnswerResponse.rainbowReward', () {
    test('alan yoksa 0 (eski sunucu)', () {
      final r = ChatQuestionAnswerResponse.fromJson({'is_correct': true, 'unmatched': false});
      expect(r.rainbowReward, 0);
    });

    test('parse edilir', () {
      final r = ChatQuestionAnswerResponse.fromJson({
        'is_correct': true,
        'unmatched': false,
        'green_reward': 2,
        'rainbow_reward': 3,
      });
      expect(r.greenReward, 2);
      expect(r.rainbowReward, 3);
    });
  });

  group('UsePowerResponse.rainbowReward', () {
    test('alan yoksa null, varsa değer', () {
      expect(UsePowerResponse.fromJson({'power_name': 'SKIP'}).rainbowReward, isNull);
      expect(UsePowerResponse.fromJson({'power_name': 'SKIP', 'rainbow_reward': 4}).rainbowReward, 4);
    });
  });

  group('PowerUsageTotals', () {
    test('yeşil, rainbow ve mor toplamları ayrı ayrı toplanır', () {
      const usages = [
        PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 1, rainbowEarned: 2),
        PowerUsageRecord(powerName: 'SKIP', purpleSpent: 20, greenEarned: 3),
      ];
      expect(usages.totalGreenEarned, 4);
      expect(usages.totalRainbowEarned, 2);
      expect(usages.totalPurpleSpent, 30);
    });

    test('rainbowEarned varsayılanı 0', () {
      const usage = PowerUsageRecord(powerName: 'ANSWER', purpleSpent: 0, greenEarned: 5);
      expect(usage.rainbowEarned, 0);
    });
  
    group('güç başına gruplama (sonuç kartlarının satırları)', () {
      const usages = [
        PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 1),
        PowerUsageRecord(powerName: 'ANSWER', purpleSpent: 0, greenEarned: 5),
        PowerUsageRecord(powerName: 'SKIP', purpleSpent: 20, greenEarned: 0),
        PowerUsageRecord(powerName: 'HALF', purpleSpent: 10, greenEarned: 2),
      ];

      test('greenByPower: aynı güç toplanır, ilk görülme sırası korunur, 0 yeşil atlanır', () {
        expect(usages.greenByPower, {'HALF': 3, 'ANSWER': 5});
        expect(usages.greenByPower.keys, ['HALF', 'ANSWER']);
      });

      test('purpleByPower: aynı güç toplanır, ilk görülme sırası korunur, 0 mor atlanır', () {
        expect(usages.purpleByPower, {'HALF': 20, 'SKIP': 20});
        expect(usages.purpleByPower.keys, ['HALF', 'SKIP']);
      });

      test('kayıt yoksa boş', () {
        expect(const <PowerUsageRecord>[].greenByPower, isEmpty);
        expect(const <PowerUsageRecord>[].purpleByPower, isEmpty);
      });
    });
  });

  group('PowerUsageRecord fabrikaları', () {
    test('fromPowerUse: cost + green_reward + rainbow_reward parse edilir', () {
      final data = UsePowerResponse.fromJson({
        'power_name': 'HALF',
        'cost': 10,
        'green_reward': 2,
        'rainbow_reward': 3,
      });

      final record = PowerUsageRecord.fromPowerUse('HALF', data);

      expect(record, isNotNull);
      expect(record!.powerName, 'HALF');
      expect(record.purpleSpent, 10);
      expect(record.greenEarned, 2);
      expect(record.rainbowEarned, 3);
    });

    test('fromPowerUse: odul alanlari yoksa 0', () {
      final data = UsePowerResponse.fromJson({'power_name': 'SKIP', 'cost': 10});

      final record = PowerUsageRecord.fromPowerUse('SKIP', data);

      expect(record, isNotNull);
      expect(record!.greenEarned, 0);
      expect(record.rainbowEarned, 0);
    });

    test('fromPowerUse: cost yoksa null', () {
      final data = UsePowerResponse.fromJson({'power_name': 'ORACLE'});
      expect(PowerUsageRecord.fromPowerUse('ORACLE', data), isNull);
    });

    test('fromPowerUse: cost 0 ise null', () {
      final data = UsePowerResponse.fromJson({'power_name': 'ORACLE', 'cost': 0});
      expect(PowerUsageRecord.fromPowerUse('ORACLE', data), isNull);
    });

    test('fromAnswer: green > 0, rainbow 0 → kayit uretilir', () {
      final response = ChatQuestionAnswerResponse.fromJson({
        'is_correct': true,
        'unmatched': false,
        'green_reward': 2,
      });

      final record = PowerUsageRecord.fromAnswer(response);

      expect(record, isNotNull);
      expect(record!.powerName, 'ANSWER');
      expect(record.purpleSpent, 0);
      expect(record.greenEarned, 2);
      expect(record.rainbowEarned, 0);
    });

    test('fromAnswer: green 0, rainbow > 0 → kayit uretilir (genisletilmis kosul)', () {
      final response = ChatQuestionAnswerResponse.fromJson({
        'is_correct': true,
        'unmatched': false,
        'rainbow_reward': 4,
      });

      final record = PowerUsageRecord.fromAnswer(response);

      expect(record, isNotNull);
      expect(record!.powerName, 'ANSWER');
      expect(record.purpleSpent, 0);
      expect(record.greenEarned, 0);
      expect(record.rainbowEarned, 4);
    });

    test('fromAnswer: ikisi de 0/eksik ise null', () {
      final response = ChatQuestionAnswerResponse.fromJson({
        'is_correct': true,
        'unmatched': false,
      });
      expect(PowerUsageRecord.fromAnswer(response), isNull);
    });
  });
}
