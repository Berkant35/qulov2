import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_power_mixin.dart';

/// Kurtarmanın yerel bakiyeye yansıması: ücretsiz ikinci şans kullanıldıysa
/// envanter/mor DÜŞÜLMEZ (sunucu düşmedi — yerel bakiye gerçeğin altına inerdi).
void main() {
  test('free_second_chance_used → settlePowerSpend çağrılmaz, kaynak ikinci şans', () {
    var settled = 0;

    final source = rescueSpendSource(
      const QuizAnswerResponse(isCorrect: true, freeSecondChanceUsed: true),
      settle: () {
        settled++;
        return true;
      },
    );

    expect(settled, 0);
    expect(source, AnalyticsEvents.sourceFreeSecondChance);
  });

  test('ücretli kurtarma: envanterden düşüldüyse kaynak envanter', () {
    final source = rescueSpendSource(
      const QuizAnswerResponse(isCorrect: true, freeSecondChanceUsed: false),
      settle: () => true,
    );
    expect(source, AnalyticsEvents.sourceInventory);
  });

  test('eski sunucu (alan yok): envanter yoksa mor düşülür', () {
    var settled = 0;
    final source = rescueSpendSource(
      const QuizAnswerResponse(isCorrect: true),
      settle: () {
        settled++;
        return false;
      },
    );
    expect(settled, 1);
    expect(source, AnalyticsEvents.sourceDiamond);
  });
}
