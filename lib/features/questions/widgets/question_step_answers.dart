import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class QuestionStepAnswers extends StatelessWidget {
  final TextEditingController answer1Controller;
  final TextEditingController answer2Controller;
  final TextEditingController answer3Controller;
  final TextEditingController answer4Controller;
  final TextEditingController hintController;
  final int correctAnswer;
  final ValueChanged<int> onCorrectAnswerChanged;

  const QuestionStepAnswers({
    super.key,
    required this.answer1Controller,
    required this.answer2Controller,
    required this.answer3Controller,
    required this.answer4Controller,
    required this.hintController,
    required this.correctAnswer,
    required this.onCorrectAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controllers = [
      answer1Controller,
      answer2Controller,
      answer3Controller,
      answer4Controller,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(4, (i) {
            final num = i + 1;
            final isCorrect = correctAnswer == num;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => onCorrectAnswerChanged(num),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect
                            ? AppColors.secondary
                            : Colors.transparent,
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.secondary
                              : context.appColors.textHint,
                          width: 2,
                        ),
                      ),
                      child: isCorrect
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppTextField(
                      controller: controllers[i],
                      label: context
                          .tr('answer_n')
                          .replaceAll('{n}', '$num'),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: i < 3
                          ? TextInputAction.next
                          : TextInputAction.done,
                      suffixIcon: isCorrect
                          ? Icon(Icons.check_circle,
                              color: AppColors.secondary, size: 20)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('correct_answer'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Hint field
          AppTextField(
            controller: hintController,
            label: context.tr('question_create_hint_label'),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            prefixIcon: QIcon(QIcons.icLightbulb, size: 18, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}
