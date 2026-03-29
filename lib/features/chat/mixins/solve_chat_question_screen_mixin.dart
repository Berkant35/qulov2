import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/screens/solve_chat_question_screen.dart';
import 'package:qulo_v2/features/chat/widgets/abandon_warning_dialog.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_rescue.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

mixin SolveChatQuestionScreenMixin
    on ConsumerState<SolveChatQuestionScreen> {
  final timerKey = GlobalKey<QuizTimerState>();

  String? selectedOption;
  bool isSubmitting = false;
  Set<String> removedOptions = {};
  String? suggestedOption;
  bool hintVisible = false;
  String? hintText;
  late bool powerBlockActive;
  bool answered = false;
  bool timedOut = false;

  ChatQuestionAnswerResponse? result;

  int _extraTimeAdded = 0;
  List<PowerUsageRecord> powerUsages = [];

  int get startTime => widget.question.timeLimitSeconds;

  void initMixin() {
    powerBlockActive = widget.question.isPowerBlocked;

    // Guard: don't allow re-solving answered questions
    if (widget.question.isAnswered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(false);
      });
      return;
    }

    // Fetch power inventory (deferred to avoid modifying provider during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final exchange = ref.read(exchangeProvider);
      if (exchange.inventory.isEmpty) {
        ref.read(exchangeProvider.notifier).fetchAll();
      }
    });
  }

  void disposeMixin() {
    // No resources to dispose currently
  }

  // ── Answer ─────────────────────────────────────────────────

  Future<void> submitAnswer() async {
    if (selectedOption == null || isSubmitting) return;
    timerKey.currentState?.pause();

    setState(() => isSubmitting = true);

    final remaining = timerKey.currentState?.remainingSeconds ?? 0;
    final totalTime = startTime + _extraTimeAdded;
    final timeSpent = (totalTime - remaining).clamp(0, totalTime);

    final apiResult = await ref.read(chatRepositoryProvider).answerQuestion(
      widget.question.id,
      {'selected_option': selectedOption, 'time_spent': timeSpent},
    );

    if (!mounted) return;

    apiResult.when(
      success: (response) {
        // Track answer reward in power usages
        if (response.greenReward > 0) {
          powerUsages.add(PowerUsageRecord(
            powerName: 'ANSWER',
            purpleSpent: 0,
            greenEarned: response.greenReward,
          ));
        }
        setState(() {
          answered = true;
          result = response;
        });
      },
      failure: (f) {
        timerKey.currentState?.resume();
        setState(() => isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? context.tr('error_general'))),
        );
      },
    );
  }

  /// Called when user confirms abandon via warning dialog.
  /// Sends null selected_option to server, marks question as abandoned.
  Future<void> abandonQuestion() async {
    if (isSubmitting) return;
    timerKey.currentState?.pause();

    setState(() => isSubmitting = true);

    final remaining = timerKey.currentState?.remainingSeconds ?? 0;
    final totalTime = startTime + _extraTimeAdded;
    final timeSpent = (totalTime - remaining).clamp(0, totalTime);

    final apiResult = await ref.read(chatRepositoryProvider).answerQuestion(
      widget.question.id,
      {'selected_option': null, 'time_spent': timeSpent},
    );

    apiResult.when(
      success: (response) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      },
      failure: (f) {
        setState(() => isSubmitting = false);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  /// Handles back/close press. Shows abandon warning if question not yet answered.
  Future<void> handleBackPress() async {
    if (answered || result != null) {
      Navigator.of(context).pop(true);
      return;
    }

    final shouldAbandon = await showAbandonWarningDialog(
      context,
      widget.question,
    );

    if (shouldAbandon && mounted) {
      await abandonQuestion();
    }
  }

  // ── Power ──────────────────────────────────────────────────

  Future<void> usePower(String powerName) async {
    timerKey.currentState?.pause();

    final apiResult = await ref.read(chatRepositoryProvider).usePower(
      widget.question.id,
      powerName,
    );

    if (!mounted) return;

    apiResult.when(
      success: (data) {
        ref.invalidate(diamondProvider);
        ref.invalidate(exchangeProvider);

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
            if (data.suggestedOption != null &&
                !removedOptions.contains(data.suggestedOption)) {
              setState(() => suggestedOption = data.suggestedOption);
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
            _extraTimeAdded += extraSec;
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
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          await PaywallBottomSheetContent.show(ref,
              trigger: 'chat_question_power');
          if (mounted) timerKey.currentState?.resume();
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

  Future<void> submitWithSkip() async {
    setState(() => isSubmitting = true);
    final apiResult = await ref.read(chatRepositoryProvider).answerQuestion(
      widget.question.id,
      {'selected_option': 'A', 'power_used': 'SKIP'},
    );

    if (!mounted) return;

    apiResult.when(
      success: (response) {
        ref.invalidate(diamondProvider);
        setState(() {
          answered = true;
          result = response;
        });
      },
      failure: (f) {
        setState(() => isSubmitting = false);
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          PaywallBottomSheetContent.show(ref, trigger: 'chat_question_skip');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? context.tr('error_general'))),
        );
      },
    );
  }

  // ── Timeout ────────────────────────────────────────────────

  void onTimeout() {
    setState(() => timedOut = true);
    showRescueSheet();
  }

  void showRescueSheet() {
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
          Navigator.of(context).pop();
          submitGiveUp();
        },
      );
      },
    );
  }

  Future<void> submitGiveUp() async {
    setState(() => isSubmitting = true);
    final apiResult = await ref.read(chatRepositoryProvider).handleTimeout(
      widget.question.id,
    );

    if (!mounted) return;

    apiResult.when(
      success: (data) {
        setState(() {
          answered = true;
          result = ChatQuestionAnswerResponse(
            isCorrect: false,
            unmatched: false,
          );
        });
      },
      failure: (f) {
        setState(() => isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? 'Bir hata oluştu')),
        );
      },
    );
  }

  // ── Rescue (after wrong answer) ────────────────────────────

  Future<void> handleRescue() async {
    final apiResult = await ref.read(chatRepositoryProvider).rescueQuestion(
      widget.question.id,
    );

    if (!mounted) return;

    apiResult.when(
      success: (response) {
        ref.invalidate(diamondProvider);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? 'Kurtarma başarısız')),
        );
      },
    );
  }

  void selectOption(String optionKey) {
    if (!isSubmitting) {
      setState(() => selectedOption = optionKey);
    }
  }
}
