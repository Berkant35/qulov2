import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';
import 'package:qulo_v2/features/power_demo/constants/power_demo_keys.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_question.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_power_bar.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_stage.dart';

/// [PowerDemoView]'da ne çizileceği: o anki durumdan türetilen, yan etkisiz değerler.
/// Durumu ve eylemleri `PowerDemoViewMixin` tutar; bu mixin yalnız okur.
mixin PowerDemoDisplayMixin on ConsumerState<PowerDemoView> {
  /// Ek Süre adımı: sayaç 11'den başlar — 10'da nabız başlar, 5'te durur ("süre bitiyor" anı).
  static const _timeExtendStepStartSeconds = 11;

  PowerDemoScenario get scenario;

  /// Doğru Say sonrası kısa süre ekranda tutulan (kenara kayan) sorunun indeksi.
  int? get heldStepIndex;

  /// Doğru cevaptan sonraki kısa "Doğru!" geri bildirimi açık mı.
  bool get showCorrectFlash;

  /// Ekrandaki soru: Doğru Say sonrası kısa süre eski soru (kenara kayarken).
  PowerDemoQuestion shownQuestion(PowerDemoProgress p) =>
      scenario.questions[heldStepIndex ?? p.stepIndex];

  /// Başlıktaki adım; Doğru Say'da kart kenara kayarken hâlâ o adım.
  int? headerStep(PowerDemoProgress p) =>
      p.phase == PowerDemoPhase.intro || p.phase == PowerDemoPhase.skipped
      ? null
      : (heldStepIndex ?? p.stepIndex) + 1;

  /// Başlıktaki "Atla" çalışır mı: kapanışta ve atlandıktan sonra yok (makine yok sayar —
  /// ölü düğme görünmesin).
  bool canSkip(PowerDemoProgress p) =>
      p.phase != PowerDemoPhase.finale && p.phase != PowerDemoPhase.skipped;

  /// Hepsini Geç kullanılınca 1: başlık sayacı sona sayar.
  int counterToken(PowerDemoProgress p) =>
      p.phase == PowerDemoPhase.skippingAll || p.phase == PowerDemoPhase.finale
      ? 1
      : 0;

  /// Bu adımda dokunulacak güç (talimat beklenirken); yoksa `null`.
  DemoPower? targetPower(PowerDemoProgress p) =>
      p.phase == PowerDemoPhase.awaitingPower && heldStepIndex == null
      ? scenario.questions[p.stepIndex].power
      : null;

  /// Cevapla görünür mü: cevap beklenirken ve bir şık seçiliyken.
  bool showsConfirm(PowerDemoProgress p) =>
      p.phase == PowerDemoPhase.awaitingAnswer && p.selectedIndex != null;

  /// Soru alanının üstündeki tek katman: kurtarma > "Doğru!" > talimat.
  PowerDemoLayer layerOf(PowerDemoProgress p) {
    if (p.phase == PowerDemoPhase.rescue) return PowerDemoLayer.rescue;
    if (showCorrectFlash) return PowerDemoLayer.correct;
    return targetPower(p) == null ? PowerDemoLayer.none : PowerDemoLayer.guide;
  }

  String guideText(PowerDemoProgress p) => context
      .tr(PowerDemoKeys.instruction(scenario.questions[p.stepIndex].power!))
      .replaceAll(
        '{count}',
        context.fmt.integer(scenario.length - p.stepIndex),
      );

  /// Etkiden sonraki tek satır; o an gösterilecek bir şey yoksa `null`.
  String? resultText(PowerDemoProgress p) {
    final DemoPower? power = heldStepIndex != null
        ? DemoPower.skip
        : switch (p.phase) {
            PowerDemoPhase.skippingAll => DemoPower.skipAll,
            PowerDemoPhase.awaitingAnswer =>
              scenario.questions[p.stepIndex].power,
            _ => null,
          };
    return power == null ? null : context.tr(PowerDemoKeys.result(power));
  }

  /// Çubuktaki güçler gerçek quiz'deki gibi: İpucu yalnız ipucu olan soruda. Hepsini Geç her
  /// adımda görünür — kalan soru arttıkça teklif kuralı zaten sağlanır (senaryo onu en az kalana
  /// göre kurar).
  List<DemoPower> barPowers(PowerDemoQuestion q) => [
    for (final power in PowerDemoPowerBar.order)
      if (power != DemoPower.hint || q.hasHint) power,
  ];

  /// Geçilen her adımın gücü + bu adımın gücü (kullanıldıysa) "kullanıldı" görünür.
  Set<DemoPower> usedPowers(PowerDemoProgress p) {
    final passed = scenario.questions.take(p.stepIndex).map((q) => q.power);
    final current = p.phase == PowerDemoPhase.awaitingPower
        ? null
        : scenario.questions[p.stepIndex].power;
    return {...passed, current}.whereType<DemoPower>().toSet();
  }

  int timerStartSeconds(PowerDemoQuestion q, int questionSeconds) =>
      q.power == DemoPower.timeExtend
      ? math.min(_timeExtendStepStartSeconds, questionSeconds)
      : questionSeconds;

  String oracleLabel(double accuracy) => context
      .tr('power_oracle_accuracy')
      .replaceAll('{percent}', context.fmt.percent((accuracy * 100).round()));

  /// Kapanış notu: onboarding'de hediye cümlesi (6 quiz gücünün hepsi > 0 ise en küçüğüyle),
  /// oturum açıkken (market / quiz öncesi) "gerçek quiz'de seni bekliyor".
  String? finaleNote(RewardsConfig rewards) {
    if (widget.entryPoint != PowerDemoEntryPoint.onboarding) {
      return context.tr('power_demo_finale_ready');
    }
    final gift = DemoPower.values
        .map((p) => rewards.starterPowers[p.apiName] ?? 0)
        .reduce(math.min);
    if (gift <= 0) return null;
    return context
        .tr('power_demo_finale_gift')
        .replaceAll('{count}', context.fmt.integer(gift));
  }
}
