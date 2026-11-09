import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';
import 'package:qulo_v2/features/power_demo/analytics/power_demo_analytics.dart';
import 'package:qulo_v2/features/power_demo/data/power_demo_outcome_store.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_outcome.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_scenario.dart';
import 'package:qulo_v2/features/power_demo/providers/power_demo_notifier.dart';
import 'package:qulo_v2/features/power_demo/screens/power_demo_view.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

/// [PowerDemoView]'un sunum dışı mantığı: eylemler (makineye ilet → kabul edildiyse analitik +
/// haptik + ekran efektleri), kronometreler, sayaç, sonuç kaydı ve çıkış.
///
/// Durumu yalnız bu mixin değiştirir; her eylem [_dispatch]'ten geçer. Makine uygunsuz eylemi
/// aynen döndürür → yok sayılan dokunuş ne olay atar ne haptik verir.
mixin PowerDemoViewMixin on ConsumerState<PowerDemoView> {
  /// Doğru Say sonrası eski kartın kenara kayıp ✓ gösterdiği süre.
  static final _skipCardHold = PowerEffectTiming.enter + PowerEffectTiming.exit;

  /// Hepsini Geç sayacının sona sayıp ✓ gösterdiği süre; sonra kutlama.
  static final _skipAllHold = PowerEffectTiming.enter * 2;

  final timerKey = GlobalKey<QuizTimerState>();

  /// Bu adımda dokunulacak güç butonu (talimat katmanının deliği).
  final guideTargetKey = GlobalKey();

  late final PowerDemoAnalytics _analytics = PowerDemoAnalytics(
    widget.entryPoint,
  );
  late final PowerDemoScenario scenario;
  final _demoClock = Stopwatch();
  final _stepClock = Stopwatch();
  Timer? _countUpTimer;
  Timer? _holdTimer;
  Timer? _skipAllTimer;

  /// Son kabul edilen durum: dispose'da `ref` okunmaz, yarıda bırakma kaydı buradan.
  late PowerDemoProgress _last;

  /// Görünüm en az bir kez kullanıcının önüne geldi mi ([PowerDemoView.isActive]).
  bool _wasActive = false;
  bool _exited = false;

  /// Doğru Say sonrası kısa süre ekranda tutulan (kenara kayan) sorunun indeksi.
  int? heldStepIndex;

  /// Doğru cevaptan sonraki kısa "Doğru!" geri bildirimi.
  bool showCorrectFlash = false;

  PowerDemoNotifier get _demo =>
      ref.read(powerDemoProvider(widget.entryPoint).notifier);
  PowerDemoProgress get _progress =>
      ref.read(powerDemoProvider(widget.entryPoint));
  HapticManager get _haptic => ref.read(hapticManagerProvider);

  void initMixin() {
    scenario = _demo.scenario;
    _last = _progress;
    _wasActive = widget.isActive;
  }

  void updateMixin() => _wasActive |= widget.isActive;

  /// Sayfadan yarıda çıkış (carousel'de kaydırma, geri tuşu) "atladı" sayılır — girişte de
  /// (Başla öncesi, `from_step 0`; spec §9.1 "hepsini atlayan"), görünüm bir kez etkin olduysa.
  /// Atla / bitiş zaten kaydedildi (faz skipped / finale): ikinci kayıt yok.
  void disposeMixin() {
    _countUpTimer?.cancel();
    _holdTimer?.cancel();
    _skipAllTimer?.cancel();
    if (_leftUnfinished(_last)) _recordSkip(_last);
  }

  // ── Eylemler ────────────────────────────────────────────────

  void onStart() => _dispatch((d) => d.start(), (_) {
    _demoClock.start();
    _analytics.start();
    _haptic.light();
  });

  void onPowerTap(DemoPower power) =>
      _dispatch((d) => d.usePower(power), (before) {
        _analytics.powerUsed(
          _stepOf(before),
          power,
          _stepClock.elapsedMilliseconds,
        );
        _haptic.light();
      });

  void onSelectAnswer(int index) =>
      _dispatch((d) => d.selectAnswer(index), (_) => _haptic.selection());

  void onSubmitAnswer() {
    var correct = false;
    _dispatch((d) => correct = d.submit(), (before) {
      _analytics.answer(_stepOf(before), correct: correct);
      if (correct) {
        _haptic.success();
        setState(() => showCorrectFlash = true);
      } else {
        _haptic.error();
      }
    });
  }

  void onRescue() => _dispatch((d) => d.rescue(), (before) {
    _analytics.rescueUsed(_stepOf(before));
    _haptic.light();
  });

  /// "Vazgeç": gerçek quiz'de quiz biter; provada ceza yok, sıradaki soruya geçilir.
  /// `rescue_used` atılmaz — kurtarmayı seçenle vazgeçen ayrışsın.
  void onDeclineRescue() => _dispatch((d) => d.rescue());

  void onSkip() => _dispatch((d) => d.skip(), (before) {
    _recordSkip(before);
    _exit();
  });

  void onFinish() => _exit();

  void onCorrectFlashDone() {
    if (!mounted) return;
    setState(() => showCorrectFlash = false);
    _restartStepClock();
  }

  /// Sayaç 5 sn'de durur: demo hiçbir adımda süreyi bitirmez.
  void onTimerCritical() => timerKey.currentState?.pause();

  int get elapsedSeconds => _demoClock.elapsed.inSeconds;

  // ── İç akış ─────────────────────────────────────────────────

  /// Eylemi makineye iletir; durum değiştiyse (kabul) önce eylem olayı, sonra geçiş etkileri.
  void _dispatch(
    void Function(PowerDemoNotifier demo) action, [
    void Function(PowerDemoProgress before)? onAccepted,
  ]) {
    final before = _progress;
    action(_demo);
    final after = _progress;
    if (identical(before, after)) return;
    _last = after;
    onAccepted?.call(before);
    _afterTransition(before, after);
  }

  void _afterTransition(PowerDemoProgress before, PowerDemoProgress after) {
    if (_entersQuestion(before, after)) _onStepEntered(after);
    if (after.extraSecondsToken != before.extraSecondsToken) _addTime();
    if (after.skipToken != before.skipToken) _holdSkippedCard(before.stepIndex);
    if (after.phase == before.phase) return;
    switch (after.phase) {
      case PowerDemoPhase.rescue:
        timerKey.currentState?.pause();
      case PowerDemoPhase.skippingAll:
        _skipAllTimer = Timer(
          _skipAllHold,
          () => _dispatch((d) => d.finishSkipAll()),
        );
      case PowerDemoPhase.finale:
        _complete(after);
      default:
        break;
    }
  }

  static bool _entersQuestion(
    PowerDemoProgress before,
    PowerDemoProgress after,
  ) {
    final asking =
        after.phase == PowerDemoPhase.awaitingPower ||
        after.phase == PowerDemoPhase.awaitingAnswer;
    return asking &&
        (before.phase == PowerDemoPhase.intro ||
            before.stepIndex != after.stepIndex);
  }

  void _onStepEntered(PowerDemoProgress p) {
    // Önceki adımın Ek Süre sayımı yeni soruya saniye eklemesin (sayaç durumu soru başına sıfırlanır).
    _countUpTimer?.cancel();
    _analytics.stepView(_stepOf(p), scenario.questions[p.stepIndex].power);
    _restartStepClock();
  }

  /// Ek Süre: duran sayaç yeniden akar, sayı N kadar yukarı sayar (hareketi azaltta tek seferde).
  void _addTime() {
    final timer = timerKey.currentState;
    final seconds = ref.read(economyConfigProvider).timing.timeExtendSeconds;
    if (timer == null || seconds <= 0) return;
    timer.resume();
    _countUpTimer?.cancel();
    if (reduceMotionOf(context)) {
      timer.addSeconds(seconds);
      return;
    }
    var added = 0;
    _countUpTimer = Timer.periodic(PowerEffectTiming.enter ~/ seconds, (tick) {
      timerKey.currentState?.addSeconds(1);
      if (++added >= seconds) tick.cancel();
    });
  }

  void _holdSkippedCard(int stepIndex) {
    setState(() => heldStepIndex = stepIndex);
    _holdTimer?.cancel();
    _holdTimer = Timer(_skipCardHold, () {
      if (!mounted) return;
      setState(() => heldStepIndex = null);
      _restartStepClock();
    });
  }

  void _complete(PowerDemoProgress p) {
    _demoClock.stop();
    _analytics.complete(
      durationMs: _demoClock.elapsedMilliseconds,
      wrongAnswers: p.wrongAnswers,
    );
    _saveOutcome(const PowerDemoCompleted());
    _haptic.success();
  }

  /// Atlanan adım 1 tabanlıdır; girişte (hiç başlamadan) atlamak 0.
  void _recordSkip(PowerDemoProgress before) {
    final started = before.phase != PowerDemoPhase.intro;
    final step = started ? _stepOf(before) : 0;
    _analytics.skip(
      fromStep: step,
      power: started ? scenario.questions[before.stepIndex].power : null,
      durationMs: _demoClock.elapsedMilliseconds,
    );
    _saveOutcome(PowerDemoSkipped(step));
  }

  /// Yalnız onboarding sonucu saklanır (kayıt sonrası raporlanır).
  void _saveOutcome(PowerDemoOutcome outcome) {
    if (widget.entryPoint != PowerDemoEntryPoint.onboarding) return;
    unawaited(PowerDemoOutcomeStore.saveOnboarding(outcome));
  }

  void _exit() {
    if (_exited) return;
    _exited = true;
    widget.onExit();
  }

  void _restartStepClock() => _stepClock
    ..reset()
    ..start();

  static int _stepOf(PowerDemoProgress p) => p.stepIndex + 1;

  bool _leftUnfinished(PowerDemoProgress p) => switch (p.phase) {
    PowerDemoPhase.finale || PowerDemoPhase.skipped => false,
    PowerDemoPhase.intro => _wasActive,
    _ => true,
  };
}
