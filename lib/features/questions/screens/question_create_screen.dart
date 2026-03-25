import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/features/questions/mixins/question_create_screen_mixin.dart';
import 'package:qulo_v2/features/questions/widgets/question_create_bottom_bar.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_answers.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_question.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_settings.dart';
import 'package:qulo_v2/features/questions/widgets/step_indicator.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

class QuestionCreateScreen extends ConsumerStatefulWidget {
  final QuestionModel? editQuestion;
  final AiSuggestionModel? prefillSuggestion;

  const QuestionCreateScreen({
    super.key,
    this.editQuestion,
    this.prefillSuggestion,
  });

  @override
  ConsumerState<QuestionCreateScreen> createState() =>
      _QuestionCreateScreenState();
}

class _QuestionCreateScreenState extends ConsumerState<QuestionCreateScreen>
    with QuestionCreateScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onDependenciesChanged();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEditMode
          ? context.tr('question_edit_title')
          : context.tr('question_create_title'),
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: StepIndicator(
              currentStep: currentStep,
              labels: [
                context.tr('question_create_step_question'),
                context.tr('question_create_step_answers'),
                context.tr('question_create_step_settings'),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                QuestionStepQuestion(
                  questionTextController: questionTextController,
                  selectedLocale: selectedLocale,
                  selectedCategory: selectedCategory,
                  onLocaleChanged: (v) => setState(() => selectedLocale = v),
                  onCategoryChanged: (v) =>
                      setState(() => selectedCategory = v),
                ),
                QuestionStepAnswers(
                  answer1Controller: answer1Controller,
                  answer2Controller: answer2Controller,
                  answer3Controller: answer3Controller,
                  answer4Controller: answer4Controller,
                  hintController: hintController,
                  correctAnswer: correctAnswer,
                  onCorrectAnswerChanged: (v) =>
                      setState(() => correctAnswer = v),
                ),
                QuestionStepSettings(
                  selectedTimeLimit: selectedTimeLimit,
                  timePresets:
                      ref.read(economyConfigProvider).timing.timePresets,
                  onTimeLimitChanged: (v) =>
                      setState(() => selectedTimeLimit = v),
                ),
              ],
            ),
          ),
          QuestionCreateBottomBar(
            questionTextController: questionTextController,
            answer1Controller: answer1Controller,
            answer2Controller: answer2Controller,
            answer3Controller: answer3Controller,
            answer4Controller: answer4Controller,
            hintController: hintController,
            correctAnswer: correctAnswer,
            selectedCategory: selectedCategory,
            selectedTimeLimit: selectedTimeLimit,
            currentStep: currentStep,
            isSaving: isSaving,
            isEditMode: isEditMode,
            canGoNext: canGoNext(),
            onBack: goBack,
            onNext: goNext,
            onSave: save,
          ),
        ],
      ),
    );
  }
}
