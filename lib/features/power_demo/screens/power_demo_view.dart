import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/power_demo/domain/demo_power.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_entry_point.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_progress.dart';
import 'package:qulo_v2/features/power_demo/mixins/power_demo_display_mixin.dart';
import 'package:qulo_v2/features/power_demo/mixins/power_demo_view_mixin.dart';
import 'package:qulo_v2/features/power_demo/providers/power_demo_notifier.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_finale.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_guide_overlay.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_header.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_intro.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_power_bar.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_question_card.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_rescue.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_stage.dart';
import 'package:qulo_v2/features/power_demo/widgets/power_demo_timer.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_feedback_overlay.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_confirm_button.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

/// Güç demosu: gerçek quiz ekranının provası — her güç bir kez, kendi elinle, sunucusuz.
///
/// Gömülü görünümdür (route değil): tanıtım carousel'i ve `power-demo` route'u aynı görünümü
/// [entryPoint] ile açar. Hiçbir yere gitmez; bitişte ya da "Atla"da yalnız [onExit] çağrılır.
/// Arka planı kendisi boyar ki koyu carousel üstünde de okunur kalsın.
///
/// Yarıda bırakılırsa (dispose) "atladı" kaydını kendisi atar — carousel'de kaydırma, route'ta
/// geri tuşu; girişte (Başla öncesi) de, görünüm bir kez [isActive] olduysa.
class PowerDemoView extends ConsumerStatefulWidget {
  const PowerDemoView({
    super.key,
    required this.entryPoint,
    required this.onExit,
    this.isActive = true,
  });

  final PowerDemoEntryPoint entryPoint;

  /// Demo bitti (kapanışta İleri) ya da atlandı — bir kez çağrılır.
  final VoidCallback onExit;

  /// Görünüm kullanıcının önünde mi: carousel'de geçerli sayfa (route'ta hep). Kaydırırken bir
  /// anlığına kurulup kaldırılan, hiç geçerli sayfa olmamış görünüm girişte "atladı" sayılmaz.
  final bool isActive;

  @override
  ConsumerState<PowerDemoView> createState() => _PowerDemoViewState();
}

class _PowerDemoViewState extends ConsumerState<PowerDemoView>
    with PowerDemoViewMixin, PowerDemoDisplayMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void didUpdateWidget(PowerDemoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // watch: provider autoDispose — ekran açık kaldıkça demo durumu yaşar.
    final progress = ref.watch(powerDemoProvider(widget.entryPoint));
    final economy = ref.watch(economyConfigProvider);
    final timing = economy.timing;
    final shown = shownQuestion(progress);
    final body = switch (progress.phase) {
      PowerDemoPhase.intro => PowerDemoIntro(onStart: onStart),
      PowerDemoPhase.finale => PowerDemoFinale(
        totalQuestions: scenario.length,
        seconds: elapsedSeconds,
        powersUsed: DemoPower.values.length,
        note: finaleNote(economy.rewards),
        onContinue: onFinish,
      ),
      // Atlandı: çağıran sayfayı kapatırken boş kalır (soru bir kare bile görünmesin).
      PowerDemoPhase.skipped => const SizedBox.shrink(),
      _ => PowerDemoStage(
        card: PowerDemoQuestionCard(
          question: shown,
          progress: progress,
          oracleLabel: oracleLabel(economy.oracleAccuracy),
          timer: PowerDemoTimer(
            timerKey: timerKey,
            questionId: shown.id,
            seconds: timerStartSeconds(shown, timing.questionTimeSeconds),
            totalSeconds: timing.questionTimeSeconds,
            extendSeconds: timing.timeExtendSeconds,
            extendToken: progress.extraSecondsToken,
            onCritical: onTimerCritical,
          ),
          onSelect: onSelectAnswer,
        ),
        resultText: resultText(progress),
        confirm: showsConfirm(progress)
            ? QuizConfirmButton(
                isSubmitting: false,
                onSubmitAnswer: () async => onSubmitAnswer(),
              )
            : null,
        powerBar: PowerDemoPowerBar(
          powers: barPowers(shown),
          used: usedPowers(progress),
          target: targetPower(progress),
          targetKey: guideTargetKey,
          onTap: onPowerTap,
        ),
        overlay: switch (layerOf(progress)) {
          PowerDemoLayer.guide => PowerDemoGuideOverlay(
            key: ValueKey(progress.stepIndex),
            targetKey: guideTargetKey,
            text: guideText(progress),
          ),
          PowerDemoLayer.rescue => PowerDemoRescue(
            onRescue: onRescue,
            onDecline: onDeclineRescue,
          ),
          PowerDemoLayer.correct => AnswerFeedbackOverlay(
            isCorrect: true,
            onComplete: onCorrectFlashDone,
          ),
          PowerDemoLayer.none => null,
        },
      ),
    };
    return Material(
      color: context.appColors.scaffold,
      child: Column(
        children: [
          PowerDemoHeader(
            step: headerStep(progress),
            total: scenario.length,
            counterToken: counterToken(progress),
            onSkip: canSkip(progress) ? onSkip : null,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
