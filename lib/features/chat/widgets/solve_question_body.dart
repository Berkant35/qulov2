import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/question_owner_header.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_banner.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';

class SolveQuestionBody extends StatelessWidget {
  final ChatQuestionModel question;
  final GlobalKey<QuizTimerState> timerKey;
  final String? selectedOption;
  final bool isSubmitting;
  final Set<String> removedOptions;
  final String? suggestedOption;
  final bool hintVisible;
  final String? hintText;
  final bool powerBlockActive;
  final VoidCallback onTimeout;
  final ValueChanged<String> onOptionSelected;
  final Future<void> Function() onSubmit;
  final Future<void> Function(String) onPowerTap;
  final Map<String, int> powerCounts;
  final PowerCostsConfig powerCosts;

  /// Bu soruda kullanilmis gucler. Envanter kapisi kalkinca tekrar tap = tekrar
  /// ucret riski dogdu; TIME_EXTEND ve SKIP eskiden hic kapatilmiyordu.
  final Set<String> usedPowers;
  final String? senderPhotoUrl;
  final String? senderName;

  const SolveQuestionBody({
    super.key,
    required this.question,
    required this.timerKey,
    required this.selectedOption,
    required this.isSubmitting,
    required this.removedOptions,
    required this.suggestedOption,
    required this.hintVisible,
    required this.hintText,
    required this.powerBlockActive,
    required this.onTimeout,
    required this.onOptionSelected,
    required this.onSubmit,
    required this.onPowerTap,
    this.powerCounts = const {},
    this.powerCosts = PowerCostsConfig.fallback,
    this.usedPowers = const {},
    this.senderPhotoUrl,
    this.senderName,
  });

  static const _optionLabels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = question.allOptions;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuestionOwnerHeader(name: senderName, photoUrl: senderPhotoUrl),
          QuizTimer(
            key: timerKey,
            seconds: question.timeLimitSeconds,
            questionId: question.id,
            onTimeout: onTimeout,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            question.questionText,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (suggestedOption != null)
            PowerBanner(
              icon: Icons.auto_awesome,
              text: context.tr('power_oracle_desc'),
            ),
          if (hintVisible && hintText != null)
            PowerBanner(
              icon: Icons.lightbulb_outline,
              text: hintText!,
              color: Colors.amber,
            ),
          ...List.generate(options.length, (i) {
            final optionKey = _optionLabels[i];
            final isRemoved = removedOptions.contains(optionKey);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AnswerButton(
                text: options[i],
                onTap: () {
                  if (!isRemoved && !isSubmitting) {
                    onOptionSelected(optionKey);
                  }
                },
                isSelected: selectedOption == optionKey,
                isOracleSuggested: suggestedOption == optionKey,
                isDisabled: isRemoved,
              ),
            );
          }),
          if (selectedOption != null)
            _SubmitButton(
              isSubmitting: isSubmitting,
              onSubmit: onSubmit,
            ),
          const Spacer(),
          ChatQuestionPowerBar(
            optionCount: question.optionCount,
            isPowerBlocked: powerBlockActive,
            hasHint: question.hintText != null &&
                question.hintText!.isNotEmpty,
            onPowerTap: onPowerTap,
            powerCosts: powerCosts,
            disabledPowers: {
              ...usedPowers,
              if (suggestedOption != null) 'ORACLE',
              if (removedOptions.isNotEmpty) 'HALF',
              if (hintVisible) 'HINT',
            },
            powerCounts: powerCounts,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  const _SubmitButton({
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SafeTapButton(
        onTap: isSubmitting ? null : () => onSubmit(),
        builder: (context, isLoading, onTap) => ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            backgroundColor: context.appColors.primary,
          ),
          child: (isLoading || isSubmitting)
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
    );
  }
}
