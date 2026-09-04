import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';

/// Guc kullanimi ve rescue akisi.
///
/// Envanter kapisi kaldirildi: buton her zaman aktif, envanterde hak yoksa sunucu
/// dogrudan mor elmastan dusuyor. Bakiye yetmezse paywall acilir.
mixin QuizPowerMixin on QuizScreenStateMixin {
  Future<void> usePower(String power) async {
    if (isSubmitting) return;

    final quiz = ref.read(quizProvider);
    if (quiz.usedPowers.contains(power)) return;

    final hadInventory = ref.read(exchangeProvider).getCount(power) > 0;
    final cost = quiz.purpleCostOf(power);

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizPowerTap,
      params: {
        AnalyticsEvents.paramPower: power,
        AnalyticsEvents.paramHasInventory: hadInventory,
        AnalyticsEvents.paramCost: cost,
      },
    );

    final isTerminating = power == 'SKIP' || power == 'SKIP_ALL';
    if (isTerminating) timerKey.currentState?.pause();

    setState(() => isSubmitting = true);

    final result =
        await ref.read(quizProvider.notifier).answer(null, powerUsed: power);

    if (!mounted) return;
    setState(() => isSubmitting = false);

    result.when(
      success: (data) {
        powersUsed++;
        ref.read(quizProvider.notifier).markPowerUsed(power);
        // Bakiye yerel dusulur — sunucu ucreti zaten aldi, tekrar sormaya gerek yok.
        final fromInventory =
            ref.read(exchangeProvider.notifier).settlePowerSpend(power, cost);

        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.quizPowerUsed,
          params: {
            AnalyticsEvents.paramPower: power,
            AnalyticsEvents.paramSource: fromInventory
                ? AnalyticsEvents.sourceInventory
                : AnalyticsEvents.sourceDiamond,
            AnalyticsEvents.paramPurpleSpent: fromInventory ? 0 : cost,
          },
        );

        if (data.awaitingAnswer == true) {
          final powerResult = data.powerResult;
          if (powerResult != null) {
            setState(() {
              if (powerResult.containsKey('suggested_answer_index')) {
                oracleSuggestedIndex =
                    powerResult['suggested_answer_index'] as int?;
              }
              if (powerResult.containsKey('removed_indices')) {
                removedIndices =
                    (powerResult['removed_indices'] as List).cast<int>();
              }
              if (powerResult.containsKey('extra_seconds')) {
                final extra = powerResult['extra_seconds'] as int;
                timerKey.currentState?.addSeconds(extra);
              }
              if (powerResult.containsKey('hint_text')) {
                hintText = powerResult['hint_text'] as String?;
              }
            });
          }
        } else {
          if (data.isCorrect == true) totalCorrect++;
          handleSessionTransition(data.sessionStatus, data.badge);
        }
      },
      failure: (f) {
        if (isTerminating) timerKey.currentState?.resume();
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.quizPowerFailed,
          params: {
            AnalyticsEvents.paramPower: power,
            AnalyticsEvents.paramErrorCode:
                f is ServerFailure ? f.code : 'unknown',
          },
        );
        handlePowerFailure(f, power: power, pauseTimer: true);
      },
    );
  }

  Future<void> onRescue(String powerType) async {
    setState(() => isSubmitting = true);

    final cost = ref.read(quizProvider).purpleCostOf(powerType);
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.quizRescueAccepted,
      params: {AnalyticsEvents.paramPower: powerType},
    );

    final result =
        await ref.read(quizProvider.notifier).rescue(powerType: powerType);

    if (!mounted) return;
    setState(() => isSubmitting = false);

    result.when(
      success: (data) {
        powersUsed++;
        totalCorrect++;
        final fromInventory =
            ref.read(exchangeProvider.notifier).settlePowerSpend(powerType, cost);
        resetQuestionState();

        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.quizPowerUsed,
          params: {
            AnalyticsEvents.paramPower: powerType,
            AnalyticsEvents.paramSource: fromInventory
                ? AnalyticsEvents.sourceInventory
                : AnalyticsEvents.sourceDiamond,
            AnalyticsEvents.paramPurpleSpent: fromInventory ? 0 : cost,
          },
        );

        if (data.sessionStatus == 'COMPLETED') {
          logQuizComplete(matched: true);
          showGamifiedResult(matched: true, badge: data.badge ?? 'none');
        } else {
          ref.read(quizProvider.notifier).fetchCurrentQuestion();
          startQuestionTimer();
        }
      },
      failure: (f) {
        if (!mounted) return;
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.quizPowerFailed,
          params: {
            AnalyticsEvents.paramPower: powerType,
            AnalyticsEvents.paramErrorCode:
                f is ServerFailure ? f.code : 'unknown',
          },
        );
        // Rescue overlay'i ACIK KALIR — SKIP/SKIP_ALL/vazgec tuslari kullanilabilir.
        handlePowerFailure(f, power: powerType, pauseTimer: false);
      },
    );
  }

  Future<void> onDeclineRescue() async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.quizRescueDeclined);
    await ref.read(quizProvider.notifier).fail();

    if (!mounted) return;
    resetQuestionState();
    logQuizComplete(matched: false);
    showGamifiedResult(matched: false, badge: 'none');
  }

  /// Guc/rescue hatalarinin TEK ele alma noktasi (quiz gucu, quiz rescue).
  ///
  /// Sunucuda bu yolda uretilebilen tek kaynak hatasi `INSUFFICIENT_DIAMONDS`;
  /// `NO_INVENTORY` hic tanimli degil ve `DIAMOND_COOLDOWN`'in kontrolu bos stub.
  /// `POWER_ALREADY_USED` savunma hatti — buton zaten kapali olmali.
  Future<void> handlePowerFailure(
    AppFailure f, {
    required String power,
    required bool pauseTimer,
  }) async {
    final code = f is ServerFailure ? f.code : null;

    if (code == 'POWER_ALREADY_USED') {
      ref.read(quizProvider.notifier).markPowerUsed(power);
      return;
    }

    if (code == 'INSUFFICIENT_DIAMONDS') {
      if (pauseTimer) onSheetOpening();
      FunnelEvents.logAuthed(
        AnalyticsEvents.paywallShown,
        params: {AnalyticsEvents.paramTrigger: 'quiz_power'},
      );
      await PaywallBottomSheetContent.show(ref, trigger: 'quiz_power');
      if (!mounted) return;
      // RevenueCat webhook'una ~1.5s tampon — satin alma basarili olsa bile sunucu
      // credit'i bu surede isliyor; yoksa tekrar basinca bakiye eski gorunur ve
      // paywall loop'a girer.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await refreshBalances();
      if (pauseTimer && mounted) onSheetClosed();
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(f.message ?? context.tr('quiz_power_failed')),
        backgroundColor: context.appColors.error,
      ),
    );
  }

  /// Envanter + elmas bakiyesi + kullanici tazele — SADECE paywall satin alma
  /// sonrasinda (sunucu bakiyeyi bizim bilmedigimiz sekilde degistirdi).
  /// Guc kullanimi `settlePowerSpend` ile yerel dusulur, buraya gelmez.
  ///
  /// `ref.invalidate(diamondProvider)` KULLANMA — `DiamondNotifier.build()` sabit
  /// `DiamondBalance(0, 0)` donuyor, yani invalidate refetch degil SIFIRLAMA olur.
  Future<void> refreshBalances() async {
    // mounted kontrolleri sart: paywall + 1.5s tampon sonrasi kullanici quiz'den
    // cikmis olabilir; ardisik await'ler dispose edilmis container'a duser (chat ile simetrik).
    if (!mounted) return;
    await ref.read(exchangeProvider.notifier).fetchAll();
    if (!mounted) return;
    await ref.read(diamondProvider.notifier).fetchBalance();
    if (!mounted) return;
    await ref.read(userProvider.notifier).fetchMe();
  }
}
