import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/screens/solve_chat_question_screen.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_rescue.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

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

  int get startTime => widget.question.timeLimitSeconds;

  void initMixin() {
    powerBlockActive = widget.question.isPowerBlocked;
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
    final timeSpent = startTime - remaining;

    final apiResult = await ref.read(chatRepositoryProvider).answerQuestion(
      widget.question.id,
      {'selected_option': selectedOption, 'time_spent': timeSpent},
    );

    if (!mounted) return;

    apiResult.when(
      success: (response) {
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

        switch (powerName) {
          case 'ORACLE':
            if (data.suggestedOption != null) {
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
            timerKey.currentState?.addSeconds(15);
          case 'SKIP':
            setState(() {
              answered = true;
              result = ChatQuestionAnswerResponse(
                isCorrect: true,
                unmatched: false,
                rewardMediaUrl: widget.question.rewardMediaUrl,
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
      builder: (_) => ChatQuestionRescue(
        isPowerBlocked: powerBlockActive,
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
      ),
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
