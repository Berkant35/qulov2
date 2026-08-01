import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/screens/solve_chat_question_screen.dart';
import 'package:qulo_v2/features/chat/widgets/abandon_warning_dialog.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/providers/api_provider.dart';
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

  /// TIME_EXTEND ile eklenen toplam sure — sonuc ekraninda gosteriliyor.
  /// `ChatQuestionPowerMixin` (ayri dosya) yazdigi icin public.
  int extraTimeAdded = 0;
  List<PowerUsageRecord> powerUsages = [];

  /// Bu soruda kullanilmis gucler — butonu kapatir. Sunucu ikinci kullanimi zaten
  /// POWER_ALREADY_USED ile reddediyor; bu gorsel geri bildirim.
  final Set<String> usedPowers = {};

  int get startTime => widget.question.timeLimitSeconds;

  /// `ChatQuestionPowerMixin` saglar — timeout akisi rescue sheet'ini aciyor.
  void showRescueSheet();

  /// `ChatQuestionPowerMixin` saglar — envanter/elmas/kullanici tazeleme.
  Future<void> refreshBalances();

  void initMixin() {
    powerBlockActive = widget.question.isPowerBlocked;

    // Sunucudan gelen durumu hidrate et — ekran yeniden acildiginda kullanilmis
    // gucler acik gorunmesin (quiz'de `used_powers` ile ayni is).
    usedPowers.addAll(widget.question.powersUsed.map((p) => p.toString()));

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
    final totalTime = startTime + extraTimeAdded;
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
    final totalTime = startTime + extraTimeAdded;
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
        timerKey.currentState?.resume();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('error_chat_generic'))),
          );
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

    if (timedOut) return;

    final shouldAbandon = await showAbandonWarningDialog(
      context,
      widget.question,
    );

    if (shouldAbandon && mounted) {
      await abandonQuestion();
    }
  }

  // ── Power ──────────────────────────────────────────────────

  Future<void> submitWithSkip() async {
    setState(() => isSubmitting = true);
    final apiResult = await ref.read(chatRepositoryProvider).answerQuestion(
      widget.question.id,
      {'selected_option': 'A', 'power_used': 'SKIP'},
    );

    if (!mounted) return;

    await apiResult.when(
      success: (response) async {
        // `ref.invalidate(diamondProvider)` DEGIL — build() sabit sifir donuyor,
        // invalidate refetch degil SIFIRLAMA olur ve bakiyeyi izleyen tum ekranlar
        // 0 gorur. SKIP burada gercek mor elmas harciyor.
        await refreshBalances();
        if (!mounted) return;
        setState(() {
          answered = true;
          result = response;
        });
      },
      failure: (f) async {
        setState(() => isSubmitting = false);
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          await PaywallBottomSheetContent.show(ref, trigger: 'chat_question_skip');
          if (!mounted) return;
          // RevenueCat webhook tamponu — yoksa satin alma sonrasi bakiye eski
          // gorunur ve paywall loop'a girer (usePower ile simetrik).
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!mounted) return;
          await refreshBalances();
          return;
        }
        if (!mounted) return;
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
          SnackBar(content: Text(f.message ?? context.tr('error_chat_generic'))),
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
