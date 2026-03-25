import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/questions/widgets/question_preview_card.dart';

class QuestionCreateBottomBar extends StatelessWidget {
  final TextEditingController questionTextController;
  final TextEditingController answer1Controller;
  final TextEditingController answer2Controller;
  final TextEditingController answer3Controller;
  final TextEditingController answer4Controller;
  final TextEditingController hintController;
  final int correctAnswer;
  final String? selectedCategory;
  final int selectedTimeLimit;
  final int currentStep;
  final bool isSaving;
  final bool isEditMode;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSave;

  const QuestionCreateBottomBar({
    super.key,
    required this.questionTextController,
    required this.answer1Controller,
    required this.answer2Controller,
    required this.answer3Controller,
    required this.answer4Controller,
    required this.hintController,
    required this.correctAnswer,
    required this.selectedCategory,
    required this.selectedTimeLimit,
    required this.currentStep,
    required this.isSaving,
    required this.isEditMode,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.appColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuestionPreviewCard(
              questionText: questionTextController.text,
              answer1: answer1Controller.text,
              answer2: answer2Controller.text,
              answer3: answer3Controller.text,
              answer4: answer4Controller.text,
              correctAnswer: correctAnswer,
              category: selectedCategory,
              timeLimit: selectedTimeLimit,
              hintText: hintController.text,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.appColors.border),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      child: Text(context.tr('cancel')),
                    ),
                  ),
                if (currentStep > 0)
                  const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : currentStep == 2
                            ? (canGoNext ? onSave : null)
                            : (canGoNext ? onNext : null),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appColors.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: isSaving
                        ? const AppLoadingWidget.small()
                        : Text(
                            currentStep == 2
                                ? (isEditMode
                                    ? context.tr('question_create_update')
                                    : context.tr('question_create_save'))
                                : context.tr('next'),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
