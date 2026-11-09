import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_effects.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';

/// Güç demosunun durum makinesi: sunucusuz, saf, deterministik.
///
/// Her metot (mevcut durum, eylem) → yeni durum. **Faz uygun değilse ya da eylem geçersizse
/// girdi AYNEN (`identical`) döner:** hızlı çift dokunuş (güce iki kez, efekt sürerken cevaba)
/// ikinci eylemi yok sayar, adım iki kez ilerlemez. Çağıran (`state = machine.x(state)`) ek
/// kontrol yapmaz; durum değişmediyse zaten bildirim gitmez.
class PowerDemoMachine {
  PowerDemoMachine(this.scenario);

  final PowerDemoScenario scenario;

  PowerDemoProgress initial() =>
      const PowerDemoProgress(stepIndex: 0, phase: PowerDemoPhase.intro);

  /// Giriş → ilk soru.
  PowerDemoProgress start(PowerDemoProgress p) {
    if (p.phase != PowerDemoPhase.intro) return p;
    return _enterStep(p, 0);
  }

  /// Güç adımında gücün kendisine dokunuldu. Yanlış güç / yanlış faz yok sayılır.
  PowerDemoProgress usePower(PowerDemoProgress p, DemoPower power) {
    final question = _question(p);
    final wrongMoment =
        p.phase != PowerDemoPhase.awaitingPower || question.power != power;
    // İpucu olmayan soruda İpucu gücü yok (gerçek quiz de HINT'i gizler).
    final noHint = power == DemoPower.hint && !question.hasHint;
    if (wrongMoment || noHint) return p;

    final used = p.copyWith(powerUsedAtStep: p.stepIndex);
    final answering = used.copyWith(phase: PowerDemoPhase.awaitingAnswer);
    return switch (power) {
      DemoPower.timeExtend => answering.copyWith(
        extraSecondsToken: p.extraSecondsToken + 1,
      ),
      // Demo deterministik: Kâhin hep doğru şıkkı önerir (etiket gerçek oranı gösterir).
      DemoPower.oracle => answering.copyWith(
        oracleIndex: question.correctIndex,
      ),
      DemoPower.half => answering.copyWith(
        removedIndices: halfRemovedIndices(
          optionCount: question.optionCount,
          correctIndex: question.correctIndex,
          keepIndex: p.oracleIndex,
        ),
      ),
      DemoPower.hint => answering.copyWith(hintVisible: true),
      DemoPower.skip => _enterStep(
        used.copyWith(skipToken: p.skipToken + 1),
        p.stepIndex + 1,
      ),
      DemoPower.skipAll => used.copyWith(phase: PowerDemoPhase.skippingAll),
    };
  }

  /// Hepsini Geç sayacı sona saydı → kutlama. Yalnız [PowerDemoPhase.skippingAll]'da çalışır.
  PowerDemoProgress finishSkipAll(PowerDemoProgress p) {
    if (p.phase != PowerDemoPhase.skippingAll) return p;
    return p.copyWith(
      phase: PowerDemoPhase.finale,
      stepIndex: scenario.length - 1,
    );
  }

  /// Şık seçimi (onaylanmaz). Güç adımında, güçten önce, elenmiş şıkka ya da aralık dışına
  /// dokunuş yok sayılır.
  PowerDemoProgress selectAnswer(PowerDemoProgress p, int index) {
    if (p.phase != PowerDemoPhase.awaitingAnswer) return p;
    final inRange = index >= 0 && index < _question(p).optionCount;
    final unavailable =
        !inRange ||
        p.removedIndices.contains(index) ||
        index == p.selectedIndex;
    if (unavailable) return p;
    return p.copyWith(selectedIndex: index);
  }

  /// Seçilen şıkkı onaylar. Demoda yanlış cevap yoktur: hangi şık seçilirse seçilsin doğru sayılır
  /// ve sonraki soruya geçilir (kurtarma kartı çıkmaz, [PowerDemoProgress.wrongAnswers] 0 kalır).
  /// Yok sayılırsa `(next: p, correct: false)` döner — çağıran yok sayılmayı `identical(next, p)`
  /// ile ayırt eder.
  ({PowerDemoProgress next, bool correct}) submit(PowerDemoProgress p) {
    if (p.phase != PowerDemoPhase.awaitingAnswer || p.selectedIndex == null) {
      return (next: p, correct: false);
    }
    return (next: _enterStep(p, p.stepIndex + 1), correct: true);
  }

  /// "Doğru Say ile kurtar" (demoda bedava) → sonraki soru.
  PowerDemoProgress rescue(PowerDemoProgress p) {
    if (p.phase != PowerDemoPhase.rescue) return p;
    return _enterStep(p, p.stepIndex + 1);
  }

  /// "Atla" her an çalışır (bitmiş ya da zaten atlanmış demo hariç); atlanılan adım korunur.
  PowerDemoProgress skip(PowerDemoProgress p) {
    final over =
        p.phase == PowerDemoPhase.finale || p.phase == PowerDemoPhase.skipped;
    if (over) return p;
    return p.copyWith(phase: PowerDemoPhase.skipped);
  }

  PowerDemoQuestion _question(PowerDemoProgress p) =>
      scenario.questions[p.stepIndex];

  /// [index]. soruya geç: soruya özel durum (seçim, elenen şıklar, Kâhin, ipucu) temizlenir;
  /// jetonlar, yanlış sayısı ve `powerUsedAtStep` korunur. Senaryo biterse kutlama.
  PowerDemoProgress _enterStep(PowerDemoProgress p, int index) {
    if (index >= scenario.length) {
      return p.copyWith(
        phase: PowerDemoPhase.finale,
        stepIndex: scenario.length - 1,
      );
    }
    return PowerDemoProgress(
      stepIndex: index,
      phase: scenario.questions[index].power == null
          ? PowerDemoPhase.awaitingAnswer
          : PowerDemoPhase.awaitingPower,
      extraSecondsToken: p.extraSecondsToken,
      skipToken: p.skipToken,
      wrongAnswers: p.wrongAnswers,
      powerUsedAtStep: p.powerUsedAtStep,
    );
  }
}
