import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/chat/widgets/create_question_next_button.dart';
import 'package:qulo_v2/features/chat/widgets/create_question_step2_actions.dart';

class CreateQuestionBottomButtons extends StatelessWidget {
  final int currentStep;
  final bool isLoading;
  final bool isStep1Valid;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;

  const CreateQuestionBottomButtons({
    super.key,
    required this.currentStep,
    required this.isLoading,
    required this.isStep1Valid,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
    required this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
        top: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      child: currentStep == 0
          ? CreateQuestionNextButton(
              isEnabled: isStep1Valid && !isLoading,
              onNext: onNext,
            )
          : CreateQuestionStep2Actions(
              isLoading: isLoading,
              onSubmit: onSubmit,
              onBack: onBack,
              onSaveDraft: onSaveDraft,
            ),
    );
  }
}
