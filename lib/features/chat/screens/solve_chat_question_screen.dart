import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_power_bar.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_rescue.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_result.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_banner.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';

class SolveChatQuestionScreen extends ConsumerStatefulWidget {
  final ChatQuestionModel question;

  const SolveChatQuestionScreen({super.key, required this.question});

  @override
  ConsumerState<SolveChatQuestionScreen> createState() =>
      _SolveChatQuestionScreenState();
}

class _SolveChatQuestionScreenState
    extends ConsumerState<SolveChatQuestionScreen> {
  final _timerKey = GlobalKey<QuizTimerState>();

  String? _selectedOption;
  bool _isSubmitting = false;
  Set<String> _removedOptions = {};
  String? _suggestedOption;
  bool _hintVisible = false;
  String? _hintText;
  late bool _powerBlockActive;
  bool _answered = false;
  bool _timedOut = false;

  // Result state
  ChatQuestionAnswerResponse? _result;

  int get _startTime => widget.question.timeLimitSeconds;

  @override
  void initState() {
    super.initState();
    _powerBlockActive = widget.question.isPowerBlocked;
  }

  // ── Answer ─────────────────────────────────────────────────

  Future<void> _submitAnswer() async {
    if (_selectedOption == null || _isSubmitting) return;
    _timerKey.currentState?.pause();

    // Client-side correctness check — don't send to backend yet if wrong (rescue chance)
    // correct_option may be hidden by server, so we send to backend and check response
    setState(() => _isSubmitting = true);

    final remaining = _timerKey.currentState?.remainingSeconds ?? 0;
    final timeSpent = _startTime - remaining;

    final result = await ref.read(chatRepositoryProvider).answerQuestion(
      widget.question.id,
      {'selected_option': _selectedOption, 'time_spent': timeSpent},
    );

    if (!mounted) return;

    result.when(
      success: (response) {
        setState(() {
          _answered = true;
          _result = response;
        });
      },
      failure: (f) {
        _timerKey.currentState?.resume();
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? 'Bir hata oluştu')),
        );
      },
    );
  }

  // ── Power ──────────────────────────────────────────────────

  Future<void> _usePower(String powerName) async {
    _timerKey.currentState?.pause();

    final result = await ref.read(chatRepositoryProvider).usePower(
      widget.question.id,
      powerName,
    );

    if (!mounted) return;

    result.when(
      success: (data) {
        ref.invalidate(diamondProvider);

        switch (powerName) {
          case 'ORACLE':
            if (data.suggestedOption != null) {
              setState(() => _suggestedOption = data.suggestedOption);
            }
          case 'HALF':
            setState(() => _removedOptions = data.eliminatedOptions?.toSet() ?? {});
          case 'HINT':
            setState(() {
              _hintVisible = true;
              _hintText = data.hintText ?? widget.question.hintText;
            });
          case 'TIME_EXTEND':
            _timerKey.currentState?.addSeconds(15);
          case 'SKIP':
            // usePower SKIP already answered the question on backend
            setState(() {
              _answered = true;
              _result = ChatQuestionAnswerResponse(
                isCorrect: true,
                unmatched: false,
                rewardMediaUrl: widget.question.rewardMediaUrl,
              );
            });
            return;
          case 'POWER_UNBLOCK':
            setState(() => _powerBlockActive = false);
        }

        _timerKey.currentState?.resume();
      },
      failure: (f) async {
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          await PaywallBottomSheetContent.show(ref, trigger: 'chat_question_power');
          if (mounted) _timerKey.currentState?.resume();
        } else {
          _timerKey.currentState?.resume();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.message ?? 'Bir hata oluştu')),
          );
        }
      },
    );
  }

  Future<void> _submitWithSkip() async {
    setState(() => _isSubmitting = true);
    final result = await ref.read(chatRepositoryProvider).answerQuestion(
      widget.question.id,
      {'selected_option': 'A', 'power_used': 'SKIP'},
    );

    if (!mounted) return;

    result.when(
      success: (response) {
        ref.invalidate(diamondProvider);
        setState(() {
          _answered = true;
          _result = response;
        });
      },
      failure: (f) {
        setState(() => _isSubmitting = false);
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          PaywallBottomSheetContent.show(ref, trigger: 'chat_question_skip');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? 'Bir hata oluştu')),
        );
      },
    );
  }

  // ── Timeout ────────────────────────────────────────────────

  void _onTimeout() {
    setState(() => _timedOut = true);
    _showRescueSheet();
  }

  void _showRescueSheet() {
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
        isPowerBlocked: _powerBlockActive,
        onSkip: () {
          Navigator.of(context).pop();
          _submitWithSkip();
        },
        onPowerUnblock: () async {
          Navigator.of(context).pop();
          await _usePower('POWER_UNBLOCK');
          if (mounted && _timedOut) _showRescueSheet();
        },
        onGiveUp: () {
          Navigator.of(context).pop();
          _submitGiveUp();
        },
      ),
    );
  }

  Future<void> _submitGiveUp() async {
    setState(() => _isSubmitting = true);
    final result = await ref.read(chatRepositoryProvider).handleTimeout(
      widget.question.id,
    );

    if (!mounted) return;

    result.when(
      success: (data) {
        setState(() {
          _answered = true;
          _result = ChatQuestionAnswerResponse(
            isCorrect: false,
            unmatched: false,
          );
        });
      },
      failure: (f) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? 'Bir hata oluştu')),
        );
      },
    );
  }

  // ── Rescue (after wrong answer) ────────────────────────────

  Future<void> _handleRescue() async {
    final result = await ref.read(chatRepositoryProvider).rescueQuestion(
      widget.question.id,
    );

    if (!mounted) return;

    result.when(
      success: (response) {
        ref.invalidate(diamondProvider);
        setState(() {
          _result = response;
        });
      },
      failure: (f) {
        if (f is ServerFailure && f.code == 'INSUFFICIENT_DIAMONDS') {
          PaywallBottomSheetContent.show(ref, trigger: 'chat_question_rescue');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message ?? 'Kurtarma başarısız')),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_answered && _result != null) {
      return ChatQuestionResultScreen(
        result: _result!,
        question: widget.question,
        onRescue: !_result!.isCorrect ? _handleRescue : null,
      );
    }

    final q = widget.question;
    final theme = Theme.of(context);
    final options = q.allOptions;
    final optionLabels = ['A', 'B', 'C', 'D'];

    return PopScope(
      canPop: false,
      child: AppScaffold(
        title: q.questionText.length > 25
            ? '${q.questionText.substring(0, 25)}...'
            : q.questionText,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        padding: EdgeInsets.zero,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuizTimer(
                key: _timerKey,
                seconds: q.timeLimitSeconds,
                onTimeout: _onTimeout,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                q.questionText,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_suggestedOption != null)
                PowerBanner(
                  icon: Icons.auto_awesome,
                  text: context.tr('power_oracle_desc'),
                ),
              if (_hintVisible && _hintText != null)
                PowerBanner(
                  icon: Icons.lightbulb_outline,
                  text: _hintText!,
                  color: Colors.amber,
                ),
              ...List.generate(options.length, (i) {
                final optionKey = optionLabels[i];
                final optionText = options[i];
                final isRemoved = _removedOptions.contains(optionKey);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AnswerButton(
                    text: optionText,
                    onTap: () {
                      if (!isRemoved && !_isSubmitting) {
                        setState(() => _selectedOption = optionKey);
                      }
                    },
                    isSelected: _selectedOption == optionKey,
                    isOracleSuggested: _suggestedOption == optionKey,
                    isDisabled: isRemoved,
                  ),
                );
              }),
              if (_selectedOption != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: SafeTapButton(
                    onTap: _isSubmitting ? null : () => _submitAnswer(),
                    builder: (context, isLoading, onTap) => ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                      child: (isLoading || _isSubmitting)
                          ? const AppLoadingWidget.small()
                          : Text(
                              context.tr('quiz_confirm_answer'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              const Spacer(),
              ChatQuestionPowerBar(
                optionCount: q.optionCount,
                isPowerBlocked: _powerBlockActive,
                hasHint: q.hintText != null && q.hintText!.isNotEmpty,
                onPowerTap: _usePower,
                disabledPowers: {
                  if (_suggestedOption != null) 'ORACLE',
                  if (_removedOptions.isNotEmpty) 'HALF',
                  if (_hintVisible) 'HINT',
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
