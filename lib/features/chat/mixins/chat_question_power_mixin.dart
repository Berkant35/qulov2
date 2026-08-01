import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/funnel_events.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/mixins/solve_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_rescue.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Chat sorusunda guc kullanimi ve rescue akisi.
///
/// `SolveChatQuestionScreenMixin`'den ayrildi: envanter kapisi kaldirilinca bu
/// alan buyudu ve tek dosya 480 satira ciktu (limit 300). Quiz tarafinda da ayni
/// bolme yapildi (`QuizPowerMixin`).
mixin ChatQuestionPowerMixin on SolveChatQuestionScreenMixin {
  /// Envanter + elmas bakiyesi + kullanici tazele.
  ///
  /// `ref.invalidate(diamondProvider)` KULLANMA — `DiamondNotifier.build()` sabit
  /// `DiamondBalance(0, 0)` donuyor, invalidate refetch degil SIFIRLAMA olur.
  /// `fetchMe()` sart: AppBar bakiyesi `userProvider`'dan okuyor ve chat sorusunda
  /// mor elmas artik gercekten hareket ediyor.
  @override
  Future<void> refreshBalances() async {
    await ref.read(exchangeProvider.notifier).fetchAll();
    await ref.read(diamondProvider.notifier).fetchBalance();
    await ref.read(userProvider.notifier).fetchMe();
  }


  Future<void> usePower(String powerName) async {
    timerKey.currentState?.pause();

    // Envanter kapisi YOK — envanterde hak varsa sunucu oradan duser, yoksa
    // dogrudan mor elmastan oder. Eskiden buton fiyati gosterip tap'i engelliyordu
    // (tutulmayan soz) ve sunucudaki elmas yolu hic calismiyordu.
    final hadInventory = ref.read(exchangeProvider).getCount(powerName) > 0;

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatPowerTap,
      params: {
        AnalyticsEvents.paramPower: powerName,
        AnalyticsEvents.paramHasInventory: hadInventory,
      },
    );

    final apiResult = await ref.read(chatRepositoryProvider).usePower(
      widget.question.id,
      powerName,
    );

    if (!mounted) return;

    apiResult.when(
      success: (data) {
        refreshBalances();
        usedPowers.add(powerName);

        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.chatPowerUsed,
          params: {
            AnalyticsEvents.paramPower: powerName,
            AnalyticsEvents.paramSource: hadInventory
                ? AnalyticsEvents.sourceInventory
                : AnalyticsEvents.sourceDiamond,
            AnalyticsEvents.paramPurpleSpent: data.cost ?? 0,
          },
        );

        // Track power usage for result screen
        if (data.cost != null && data.cost! > 0) {
          powerUsages.add(PowerUsageRecord(
            powerName: powerName,
            purpleSpent: data.cost!,
            greenEarned: data.greenReward ?? 0,
          ));
        }

        switch (powerName) {
          case 'ORACLE':
            // Onerilen sik HALF ile zaten elenmisse `suggestedOption` set edilmiyordu
            // → buton acik kaliyor, kullanici tekrar odiyordu. Guc her halukarda
            // kullanilmis sayilir (usedPowers yukarida isaretlendi).
            if (data.suggestedOption != null &&
                !removedOptions.contains(data.suggestedOption)) {
              setState(() => suggestedOption = data.suggestedOption);
            } else {
              setState(() {});
            }
          case 'HALF':
            setState(() =>
                removedOptions = data.eliminatedOptions?.toSet() ?? {});
          case 'HINT':
            setState(() {
              hintVisible = true;
              hintText = data.hintText ?? widget.question.hintText;
            });
          case 'TIME_EXTEND':
            final extraSec = data.extraSeconds ?? 15;
            extraTimeAdded += extraSec;
            timerKey.currentState?.addSeconds(extraSec);
          case 'SKIP':
            setState(() {
              answered = true;
              result = ChatQuestionAnswerResponse(
                isCorrect: true,
                unmatched: false,
                rewardMediaUrl: widget.question.rewardMediaUrl,
                greenReward: data.greenReward ?? 0,
                powersUsed: const ['SKIP'],
                correctOption: data.question?.answeredOption,
                answeredOption: data.question?.answeredOption,
              );
            });
            return;
          case 'POWER_UNBLOCK':
            setState(() => powerBlockActive = false);
        }

        timerKey.currentState?.resume();
      },
      failure: (f) async {
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.chatPowerFailed,
          params: {
            AnalyticsEvents.paramPower: powerName,
            AnalyticsEvents.paramErrorCode:
                f is ServerFailure ? f.code : 'unknown',
          },
        );

        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          FunnelEvents.logAuthed(
            AnalyticsEvents.paywallShown,
            params: {AnalyticsEvents.paramTrigger: 'chat_question_power'},
          );
          await PaywallBottomSheetContent.show(ref,
              trigger: 'chat_question_power');
          if (!mounted) return;
          // RevenueCat webhook'una ~1.5s tampon — yoksa satin alma sonrasi bakiye
          // hala eski gorunur ve paywall loop'a girer (quiz ile simetrik).
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!mounted) return;
          await refreshBalances();
          if (mounted) timerKey.currentState?.resume();
        } else if (f is ServerFailure && f.code == 'POWER_ALREADY_USED') {
          // Savunma hatti — buton zaten kapali olmali. Durumu senkronize et.
          setState(() => usedPowers.add(powerName));
          timerKey.currentState?.resume();
        } else if (f is ServerFailure && f.code == 'VALIDATION_ERROR') {
          // Power block gibi durumlar — sunucu mesaji cevrilmemis Ingilizce,
          // kullaniciya ham gosterilmez.
          timerKey.currentState?.resume();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('quiz_power_failed'))),
            );
          }
        } else if (f is ServerFailure && f.code == 'RATE_LIMITED') {
          timerKey.currentState?.resume();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('error_rate_limit'))),
            );
          }
        } else {
          timerKey.currentState?.resume();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(f.message ?? context.tr('error_general'))),
          );
        }
      },
    );
  }

  @override
  void showRescueSheet() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.chatRescueShown);
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) {
        final exchange = ref.read(exchangeProvider);
        final economyConfig = ref.read(economyConfigProvider);
        final skipCount = exchange.getCount('SKIP');
        final skipCost = economyConfig.powerCosts.skip.purpleCost;
        final unblockCount = exchange.getCount('POWER_UNBLOCK');
        final unblockCost = economyConfig.powerCosts.powerUnblock.purpleCost;

        return ChatQuestionRescue(
        isPowerBlocked: powerBlockActive,
        skipCost: skipCost,
        skipCount: skipCount,
        unblockCost: unblockCost,
        unblockCount: unblockCount,
        onSkip: () {
          Navigator.of(context).pop();
          submitWithSkip();
        },
        onPowerUnblock: () async {
          Navigator.of(context).pop();
          await usePower('POWER_UNBLOCK');
          if (mounted && timedOut) showRescueSheet();
        },
        onGiveUp: () {
          AnalyticsManager.instance.logEvent(AnalyticsEvents.chatRescueDeclined);
          Navigator.of(context).pop();
          submitGiveUp();
        },
      );
      },
    );
  }

  // ── Rescue (after wrong answer) ────────────────────────────

  Future<void> handleRescue() async {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.chatRescueAccepted,
      params: {AnalyticsEvents.paramPower: 'SKIP'},
    );

    // If power block is still active, show rescue sheet instead of calling API
    if (powerBlockActive) {
      showRescueSheet();
      return;
    }

    final apiResult = await ref.read(chatRepositoryProvider).rescueQuestion(
      widget.question.id,
    );

    if (!mounted) return;

    apiResult.when(
      success: (response) {
        refreshBalances();
        setState(() {
          result = response;
        });
      },
      failure: (f) {
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          PaywallBottomSheetContent.show(ref,
              trigger: 'chat_question_rescue');
          return;
        }
        // DIAMOND_COOLDOWN ve diğer hatalar — snackbar (paywall cooldown'u atlayamaz).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? context.tr('error_rescue_failed'))),
        );
      },
    );
  }
}
