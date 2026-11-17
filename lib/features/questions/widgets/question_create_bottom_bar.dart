import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/features/questions/mixins/question_create_bottom_bar_mixin.dart';
import 'package:qulo_v2/features/questions/widgets/question_preview_card.dart';

class QuestionCreateBottomBar extends StatelessWidget
    with QuestionCreateBottomBarMixin {
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

  /// Metin kaydedildi, ses/fotoğraf yükleniyor (görsel moderasyonu ~8 sn).
  /// Kayıt bu adımdan yapıldığı için ilerleme metni burada görünür.
  final bool isUploadingMedia;
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
    this.isUploadingMedia = false,
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
                    onPressed: primaryAction(
                      currentStep: currentStep,
                      isSaving: isSaving,
                      canGoNext: canGoNext,
                      onNext: onNext,
                      onSave: onSave,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appColors.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: isSaving
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppLoadingWidget.small(),
                              if (isUploadingMedia) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    context.tr('question_media_uploading'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Text(
                            primaryLabel(
                              context,
                              currentStep: currentStep,
                              isEditMode: isEditMode,
                            ),
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
