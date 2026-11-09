import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';

void main() {
  group('PowerDemoScenario.build', () {
    test('6 gücün her biri tam bir soruda', () {
      final scenario = PowerDemoScenario.build(
        skipPurple: 50,
        skipAllPurple: 90,
      );

      for (final power in DemoPower.values) {
        expect(
          scenario.questions.where((q) => q.power == power),
          hasLength(1),
          reason: power.name,
        );
      }
    });

    test('güç sırası: timeExtend, oracle, half, hint, skip, skipAll', () {
      final scenario = PowerDemoScenario.build(
        skipPurple: 50,
        skipAllPurple: 90,
      );

      expect(scenario.questions.take(6).map((q) => q.power), [
        DemoPower.timeExtend,
        DemoPower.oracle,
        DemoPower.half,
        DemoPower.hint,
        DemoPower.skip,
        DemoPower.skipAll,
      ]);
    });

    test('prod fiyatı 50/90 → 7 soru, Hepsini Geç index 5', () {
      final scenario = PowerDemoScenario.build(
        skipPurple: 50,
        skipAllPurple: 90,
      );

      expect(scenario.length, 7);
      expect(scenario.skipAllIndex, 5);
      expect(scenario.questions.last.power, isNull);
    });

    test('fallback 20/60 → 9 soru', () {
      final scenario = PowerDemoScenario.build(
        skipPurple: 20,
        skipAllPurple: 60,
      );

      expect(scenario.length, 9);
      expect(scenario.skipAllIndex, 5);
    });

    test('fiyat 0 → ceiling (4) → 9 soru', () {
      expect(
        PowerDemoScenario.build(skipPurple: 0, skipAllPurple: 0).length,
        9,
      );
      expect(
        PowerDemoScenario.build(skipPurple: 50, skipAllPurple: 0).length,
        9,
      );
    });

    test('Hepsini Geç sorusundan sonra yalnız güçsüz sorular gelir', () {
      for (final prices in const [(50, 90), (20, 60), (0, 0), (10, 30)]) {
        final scenario = PowerDemoScenario.build(
          skipPurple: prices.$1,
          skipAllPurple: prices.$2,
        );
        final after = scenario.questions.skip(scenario.skipAllIndex + 1);

        expect(after, isNotEmpty, reason: '$prices');
        expect(after.every((q) => q.power == null), isTrue, reason: '$prices');
      }
    });

    test(
      'soru kimlikleri q1..qN, tekil ve sıralı (UI metin anahtarı buradan türer)',
      () {
        final scenario = PowerDemoScenario.build(
          skipPurple: 20,
          skipAllPurple: 60,
        );

        expect(scenario.questions.map((q) => q.id), [
          for (var i = 1; i <= scenario.length; i++) 'q$i',
        ]);
      },
    );

    test('yalnız ipucu adımının sorusunda ipucu var', () {
      final scenario = PowerDemoScenario.build(
        skipPurple: 20,
        skipAllPurple: 60,
      );

      expect(scenario.questions.where((q) => q.hasHint).map((q) => q.power), [
        DemoPower.hint,
      ]);
    });

    test(
      'her soruda doğru şık aralıkta; Yarıla sorusunda elenecek şık kalır (≥4 şık)',
      () {
        final scenario = PowerDemoScenario.build(
          skipPurple: 20,
          skipAllPurple: 60,
        );

        for (final q in scenario.questions) {
          expect(q.optionCount, inInclusiveRange(2, 4), reason: q.id);
          expect(
            q.correctIndex,
            inInclusiveRange(0, q.optionCount - 1),
            reason: q.id,
          );
        }
        final half = scenario.questions.firstWhere(
          (q) => q.power == DemoPower.half,
        );
        expect(half.optionCount, 4);
      },
    );

    test('questions değiştirilemez', () {
      final scenario = PowerDemoScenario.build(
        skipPurple: 50,
        skipAllPurple: 90,
      );

      expect(
        () => scenario.questions.add(
          const PowerDemoQuestion(id: 'x', optionCount: 2, correctIndex: 0),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
