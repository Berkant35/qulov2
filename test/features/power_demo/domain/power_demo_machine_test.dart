import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_machine.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';

/// Güç demosunun durum makinesi — sunucusuz prova. Hızlı çift dokunuş (güce iki kez,
/// efekt sürerken cevaba) ikinci eylemi yok sayar; adım iki kez ilerlemez.
void main() {
  group('prod senaryosu (50/90 → 7 soru)', () {
    late PowerDemoMachine machine;
    late PowerDemoScenario scenario;

    setUp(() {
      scenario = PowerDemoScenario.build(skipPurple: 50, skipAllPurple: 90);
      machine = PowerDemoMachine(scenario);
    });

    PowerDemoProgress started() => machine.start(machine.initial());

    PowerDemoProgress answeredCorrect(PowerDemoProgress p) {
      final picked = machine.selectAnswer(
        p,
        scenario.questions[p.stepIndex].correctIndex,
      );
      return machine.submit(picked).next;
    }

    /// Adım [step]'in güç beklediği ana kadar doğru oynar.
    PowerDemoProgress playTo(int step) {
      var p = started();
      // Sınırlı döngü: makine ilerlemeyi bırakırsa test takılmasın, kırmızı olsun.
      for (var moves = 0; p.stepIndex < step; moves++) {
        if (moves > 50) fail('adım $step\'e ulaşılamadı (takıldı: ${p.phase})');
        final power = scenario.questions[p.stepIndex].power!;
        p = machine.usePower(p, power);
        if (p.phase == PowerDemoPhase.awaitingAnswer) p = answeredCorrect(p);
      }
      return p;
    }

    group('başlangıç', () {
      test('initial: giriş fazı, 0. adım, temiz durum', () {
        final p = machine.initial();

        expect(p.phase, PowerDemoPhase.intro);
        expect(p.stepIndex, 0);
        expect(p.selectedIndex, isNull);
        expect(p.wrongAnswers, 0);
      });

      test('start: ilk adımın gücünü bekler', () {
        expect(started().phase, PowerDemoPhase.awaitingPower);
        expect(started().stepIndex, 0);
      });

      test('start yalnız giriş fazında çalışır; ikinci start yok sayılır', () {
        final p = started();

        expect(identical(machine.start(p), p), isTrue);
      });

      test('giriş fazında güç / cevap / submit yok sayılır', () {
        final p = machine.initial();

        expect(identical(machine.usePower(p, DemoPower.timeExtend), p), isTrue);
        expect(identical(machine.selectAnswer(p, 0), p), isTrue);
        final submitted = machine.submit(p);
        expect(identical(submitted.next, p), isTrue);
        expect(submitted.correct, isFalse);
        expect(identical(machine.rescue(p), p), isTrue);
      });
    });

    group('güç adımı', () {
      test('güç adımında güçten önce cevap yok sayılır', () {
        final p = started();

        expect(identical(machine.selectAnswer(p, 0), p), isTrue);
        expect(identical(machine.selectAnswer(p, 1), p), isTrue);
        // submit de (seçim yokken) yok sayılır
        expect(identical(machine.submit(p).next, p), isTrue);
      });

      test('yanlış güç yok sayılır', () {
        final p = started(); // 0. adım: timeExtend

        for (final wrong in DemoPower.values.where(
          (d) => d != DemoPower.timeExtend,
        )) {
          expect(
            identical(machine.usePower(p, wrong), p),
            isTrue,
            reason: wrong.name,
          );
        }
      });

      test('güce ikinci dokunuş yok sayılır', () {
        final once = machine.usePower(started(), DemoPower.timeExtend);
        final twice = machine.usePower(once, DemoPower.timeExtend);

        expect(identical(twice, once), isTrue);
        expect(twice.extraSecondsToken, 1);
        expect(twice.stepIndex, 0);
      });

      test('timeExtend: jeton +1, cevap fazı, adımda kullanıldı işareti', () {
        final p = machine.usePower(started(), DemoPower.timeExtend);

        expect(p.extraSecondsToken, 1);
        expect(p.phase, PowerDemoPhase.awaitingAnswer);
        expect(p.powerUsedAtStep, 0);
        expect(p.stepIndex, 0);
      });

      test('oracle: önerilen şık doğru şık (demo deterministik)', () {
        final p = machine.usePower(playTo(1), DemoPower.oracle);

        expect(p.oracleIndex, scenario.questions[1].correctIndex);
        expect(p.phase, PowerDemoPhase.awaitingAnswer);
        expect(p.powerUsedAtStep, 1);
      });

      test('half: doğru şık elenmez, 2 şık elenir, elenen şık seçilemez', () {
        final q = scenario.questions[2];
        final p = machine.usePower(playTo(2), DemoPower.half);

        expect(p.removedIndices, hasLength(2));
        expect(p.removedIndices, isNot(contains(q.correctIndex)));
        expect(p.phase, PowerDemoPhase.awaitingAnswer);

        final tapRemoved = machine.selectAnswer(p, p.removedIndices.first);
        expect(identical(tapRemoved, p), isTrue);
      });

      test('half: Kâhin şıkkı o soruda öneriliyse elenmez', () {
        // Senaryoda tek soruda tek güç var; bu yüzden özel senaryo: Yarıla + Kâhin.
        final custom = PowerDemoScenario([
          const PowerDemoQuestion(
            id: 'q1',
            optionCount: 4,
            correctIndex: 1,
            power: DemoPower.half,
          ),
          const PowerDemoQuestion(
            id: 'q2',
            optionCount: 3,
            correctIndex: 0,
            power: DemoPower.skipAll,
          ),
        ]);
        final m = PowerDemoMachine(custom);
        final p = m.start(m.initial()).copyWith(oracleIndex: 2);

        final next = m.usePower(p, DemoPower.half);

        expect(next.removedIndices, [0, 3]);
      });

      test('hint: ipucu görünür', () {
        final p = machine.usePower(playTo(3), DemoPower.hint);

        expect(p.hintVisible, isTrue);
        expect(p.phase, PowerDemoPhase.awaitingAnswer);
        expect(p.powerUsedAtStep, 3);
      });

      test('hint: ipucu olmayan soruda yok sayılır', () {
        final custom = PowerDemoScenario(const [
          PowerDemoQuestion(
            id: 'q1',
            optionCount: 3,
            correctIndex: 0,
            power: DemoPower.hint,
          ),
          PowerDemoQuestion(
            id: 'q2',
            optionCount: 3,
            correctIndex: 0,
            power: DemoPower.skipAll,
          ),
        ]);
        final m = PowerDemoMachine(custom);
        final p = m.start(m.initial());

        expect(identical(m.usePower(p, DemoPower.hint), p), isTrue);
      });
    });

    group('cevap', () {
      test('cevap fazında şık seçilir; seçim değiştirilebilir', () {
        final p = machine.usePower(started(), DemoPower.timeExtend);

        final first = machine.selectAnswer(p, 0);
        final second = machine.selectAnswer(first, 2);

        expect(first.selectedIndex, 0);
        expect(second.selectedIndex, 2);
      });

      test('aralık dışı şık yok sayılır', () {
        final p = machine.usePower(started(), DemoPower.timeExtend);
        final count = scenario.questions[0].optionCount;

        expect(identical(machine.selectAnswer(p, -1), p), isTrue);
        expect(identical(machine.selectAnswer(p, count), p), isTrue);
      });

      test('aynı şıka tekrar dokunmak durumu değiştirmez', () {
        final p = machine.selectAnswer(
          machine.usePower(started(), DemoPower.timeExtend),
          1,
        );

        expect(identical(machine.selectAnswer(p, 1), p), isTrue);
      });

      test('doğru cevap → sonraki adımın gücünü bekler, adım temizlenir', () {
        final used = machine.usePower(started(), DemoPower.timeExtend);
        final picked = machine.selectAnswer(
          used,
          scenario.questions[0].correctIndex,
        );

        final result = machine.submit(picked);

        expect(result.correct, isTrue);
        expect(result.next.stepIndex, 1);
        expect(result.next.phase, PowerDemoPhase.awaitingPower);
        expect(result.next.selectedIndex, isNull);
        expect(result.next.wrongAnswers, 0);
        expect(
          result.next.extraSecondsToken,
          1,
          reason: 'jeton adımlar arası korunur',
        );
      });

      test('submit seçim yokken yok sayılır', () {
        final p = machine.usePower(started(), DemoPower.timeExtend);
        final result = machine.submit(p);

        expect(identical(result.next, p), isTrue);
        expect(result.correct, isFalse);
      });

      test('submit awaitingAnswer dışında yok sayılır', () {
        // Seçim sızmış olsa bile faz uygun değilse onay yok sayılır.
        final outsideAnswerPhase = <PowerDemoProgress>[
          machine.initial().copyWith(selectedIndex: 0),
          started().copyWith(selectedIndex: 0), // awaitingPower
          machine.skip(started()).copyWith(selectedIndex: 0), // skipped
          machine
              .usePower(playTo(scenario.skipAllIndex), DemoPower.skipAll)
              .copyWith(selectedIndex: 0),
        ];

        for (final p in outsideAnswerPhase) {
          final result = machine.submit(p);

          expect(identical(result.next, p), isTrue, reason: p.phase.name);
          expect(result.correct, isFalse, reason: p.phase.name);
        }
      });

      test('çift submit: ikinci çağrı adımı iki kez ilerletmez', () {
        final used = machine.usePower(started(), DemoPower.timeExtend);
        final picked = machine.selectAnswer(
          used,
          scenario.questions[0].correctIndex,
        );

        final first = machine.submit(picked);
        final second = machine.submit(first.next);

        expect(first.next.stepIndex, 1);
        expect(identical(second.next, first.next), isTrue);
        expect(second.correct, isFalse);
      });

      test('yanlış şık seçilse de doğru sayılır: sonraki soru, rescue yok, wrongAnswers 0', () {
        final used = machine.usePower(started(), DemoPower.timeExtend);
        final wrongIndex =
            (scenario.questions[0].correctIndex + 1) %
            scenario.questions[0].optionCount;
        final picked = machine.selectAnswer(used, wrongIndex);

        final result = machine.submit(picked);

        expect(result.correct, isTrue);
        expect(result.next.phase, PowerDemoPhase.awaitingPower);
        expect(result.next.stepIndex, 1);
        expect(result.next.wrongAnswers, 0);
      });

      test('rescue fazında cevap/güç/submit yok sayılır', () {
        final used = machine.usePower(started(), DemoPower.timeExtend);
        final wrongIndex =
            (scenario.questions[0].correctIndex + 1) %
            scenario.questions[0].optionCount;
        final inRescue = machine
            .submit(machine.selectAnswer(used, wrongIndex))
            .next;

        expect(identical(machine.selectAnswer(inRescue, 0), inRescue), isTrue);
        expect(
          identical(machine.usePower(inRescue, DemoPower.timeExtend), inRescue),
          isTrue,
        );
        expect(identical(machine.submit(inRescue).next, inRescue), isTrue);
      });

      test('çift rescue: ikinci çağrı yok sayılır, adım iki kez ilerlemez', () {
        final used = machine.usePower(started(), DemoPower.timeExtend);
        final wrongIndex =
            (scenario.questions[0].correctIndex + 1) %
            scenario.questions[0].optionCount;
        final inRescue = machine
            .submit(machine.selectAnswer(used, wrongIndex))
            .next;

        final once = machine.rescue(inRescue);
        final twice = machine.rescue(once);

        expect(once.stepIndex, 1);
        expect(identical(twice, once), isTrue);
      });

      test('rescue yalnız rescue fazında çalışır', () {
        final p = started();

        expect(identical(machine.rescue(p), p), isTrue);
      });
    });

    group('Doğru Say (SKIP) ve Hepsini Geç (SKIP_ALL)', () {
      test('SKIP sonraki soruya geçer', () {
        final atSkip = playTo(4);

        final next = machine.usePower(atSkip, DemoPower.skip);

        expect(next.stepIndex, 5);
        expect(next.phase, PowerDemoPhase.awaitingPower);
        expect(next.skipToken, atSkip.skipToken + 1);
        expect(next.powerUsedAtStep, 4);
      });

      test('SKIP çift dokunuş: ikinci dokunuş adımı bir daha ilerletmez', () {
        final once = machine.usePower(playTo(4), DemoPower.skip);
        final twice = machine.usePower(once, DemoPower.skip);

        expect(identical(twice, once), isTrue);
        expect(twice.stepIndex, 5);
        expect(twice.skipToken, once.skipToken);
      });

      test('SKIP_ALL → skippingAll', () {
        final atSkipAll = playTo(scenario.skipAllIndex);

        final p = machine.usePower(atSkipAll, DemoPower.skipAll);

        expect(p.phase, PowerDemoPhase.skippingAll);
        expect(p.stepIndex, scenario.skipAllIndex);
        expect(p.powerUsedAtStep, scenario.skipAllIndex);
      });

      test('SKIP_ALL → finale', () {
        final skipping = machine.usePower(
          playTo(scenario.skipAllIndex),
          DemoPower.skipAll,
        );

        final finale = machine.finishSkipAll(skipping);

        expect(finale.phase, PowerDemoPhase.finale);
        expect(finale.stepIndex, scenario.length - 1, reason: 'sayaç "7/7 ✓"');
      });

      test('finishSkipAll yalnız skippingAll fazında çalışır', () {
        final p = playTo(scenario.skipAllIndex);
        final skipping = machine.usePower(p, DemoPower.skipAll);
        final finale = machine.finishSkipAll(skipping);

        expect(identical(machine.finishSkipAll(p), p), isTrue);
        expect(identical(machine.finishSkipAll(finale), finale), isTrue);
      });

      test('SKIP_ALL çift dokunuş: ikinci dokunuş yok sayılır', () {
        final once = machine.usePower(
          playTo(scenario.skipAllIndex),
          DemoPower.skipAll,
        );

        expect(
          identical(machine.usePower(once, DemoPower.skipAll), once),
          isTrue,
        );
      });

      test('finale sonrası hiçbir eylem durumu değiştirmez', () {
        final finale = machine.finishSkipAll(
          machine.usePower(playTo(scenario.skipAllIndex), DemoPower.skipAll),
        );

        for (final power in DemoPower.values) {
          expect(
            identical(machine.usePower(finale, power), finale),
            isTrue,
            reason: power.name,
          );
        }
        expect(identical(machine.selectAnswer(finale, 0), finale), isTrue);
        expect(identical(machine.submit(finale).next, finale), isTrue);
        expect(identical(machine.rescue(finale), finale), isTrue);
        expect(identical(machine.skip(finale), finale), isTrue);
      });
    });

    group('Atla', () {
      test('skip → skipped, stepIndex korunur', () {
        final atStep3 = playTo(3);

        final skipped = machine.skip(atStep3);

        expect(skipped.phase, PowerDemoPhase.skipped);
        expect(skipped.stepIndex, 3);
      });

      test(
        'skip her fazda çalışır (giriş, güç, cevap, rescue, skippingAll)',
        () {
          final used = machine.usePower(started(), DemoPower.timeExtend);
          final wrongIndex =
              (scenario.questions[0].correctIndex + 1) %
              scenario.questions[0].optionCount;
          final inRescue = machine
              .submit(machine.selectAnswer(used, wrongIndex))
              .next;
          final skipping = machine.usePower(
            playTo(scenario.skipAllIndex),
            DemoPower.skipAll,
          );

          for (final p in [
            machine.initial(),
            started(),
            used,
            inRescue,
            skipping,
          ]) {
            final skipped = machine.skip(p);
            expect(skipped.phase, PowerDemoPhase.skipped, reason: p.phase.name);
            expect(skipped.stepIndex, p.stepIndex, reason: p.phase.name);
          }
        },
      );

      test('çift skip: ikinci çağrı yok sayılır', () {
        final once = machine.skip(started());

        expect(identical(machine.skip(once), once), isTrue);
      });

      test(
        'skipped sonrası hiçbir eylem durumu değiştirmez; skippingAll bitişi de',
        () {
          final skipping = machine.usePower(
            playTo(scenario.skipAllIndex),
            DemoPower.skipAll,
          );
          final skipped = machine.skip(skipping);

          expect(identical(machine.finishSkipAll(skipped), skipped), isTrue);
          expect(
            identical(machine.usePower(skipped, DemoPower.skipAll), skipped),
            isTrue,
          );
          expect(identical(machine.selectAnswer(skipped, 0), skipped), isTrue);
          expect(identical(machine.rescue(skipped), skipped), isTrue);
        },
      );
    });

    test('uçtan uca: 6 güç sırayla, hata yok → finale, 7 soru', () {
      var p = started();
      final seen = <PowerDemoPhase>[];

      for (
        var guard = 0;
        guard < 50 && p.phase != PowerDemoPhase.finale;
        guard++
      ) {
        seen.add(p.phase);
        p = switch (p.phase) {
          PowerDemoPhase.awaitingPower => machine.usePower(
            p,
            scenario.questions[p.stepIndex].power!,
          ),
          PowerDemoPhase.awaitingAnswer => answeredCorrect(p),
          PowerDemoPhase.skippingAll => machine.finishSkipAll(p),
          _ => fail('beklenmeyen faz ${p.phase}'),
        };
      }

      expect(p.phase, PowerDemoPhase.finale);
      expect(p.wrongAnswers, 0);
      expect(p.extraSecondsToken, 1);
      expect(p.skipToken, 1);
      expect(p.stepIndex, 6);
      expect(
        seen.where((ph) => ph == PowerDemoPhase.awaitingPower),
        hasLength(6),
      );
      expect(
        seen.where((ph) => ph == PowerDemoPhase.awaitingAnswer),
        hasLength(4),
      );
    });

    test(
      'cevap beklenen adımların hepsi Hepsini Geç\'ten önce (sonrası güçsüz, hiç gösterilmez)',
      () {
        var p = started();
        final answerSteps = <int>[];
        for (var moves = 0; p.phase != PowerDemoPhase.skippingAll; moves++) {
          if (moves > 50) {
            fail('Hepsini Geç\'e ulaşılamadı (takıldı: ${p.phase})');
          }
          if (p.phase == PowerDemoPhase.awaitingPower) {
            p = machine.usePower(p, scenario.questions[p.stepIndex].power!);
          } else {
            answerSteps.add(p.stepIndex);
            p = answeredCorrect(p);
          }
        }

        expect(answerSteps, everyElement(lessThan(scenario.skipAllIndex)));
      },
    );
  });

  group('fallback senaryosu (20/60 → 9 soru)', () {
    test('uçtan uca: 9 soru, finale 9. soruda', () {
      final scenario = PowerDemoScenario.build(
        skipPurple: 20,
        skipAllPurple: 60,
      );
      final machine = PowerDemoMachine(scenario);
      var p = machine.start(machine.initial());

      for (var moves = 0; p.phase != PowerDemoPhase.finale; moves++) {
        if (moves > 50) fail('finale ulaşılamadı (takıldı: ${p.phase})');
        p = switch (p.phase) {
          PowerDemoPhase.awaitingPower => machine.usePower(
            p,
            scenario.questions[p.stepIndex].power!,
          ),
          PowerDemoPhase.awaitingAnswer =>
            machine
                .submit(
                  machine.selectAnswer(
                    p,
                    scenario.questions[p.stepIndex].correctIndex,
                  ),
                )
                .next,
          PowerDemoPhase.skippingAll => machine.finishSkipAll(p),
          _ => fail('beklenmeyen faz ${p.phase}'),
        };
      }

      expect(scenario.length, 9);
      expect(p.stepIndex, 8);
    });
  });
}
