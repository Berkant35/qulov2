import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/features/questions/screens/question_create_screen.dart';
import 'package:qulo_v2/providers/question_provider.dart';

mixin QuestionCreateScreenMixin on ConsumerState<QuestionCreateScreen> {
  final pageController = PageController();
  int currentStep = 0;
  bool isSaving = false;

  final questionTextController = TextEditingController();
  final answer1Controller = TextEditingController();
  final answer2Controller = TextEditingController();
  final answer3Controller = TextEditingController();
  final answer4Controller = TextEditingController();
  final hintController = TextEditingController();
  int correctAnswer = 1;
  String? selectedCategory;
  int selectedTimeLimit = 30;
  late String selectedLocale;

  bool get isEditMode => widget.editQuestion != null;
  bool didComplete = false;

  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.questionCreateStart);
    if (isEditMode) {
      final q = widget.editQuestion!;
      questionTextController.text = q.questionText;
      answer1Controller.text = q.answer1;
      answer2Controller.text = q.answer2;
      answer3Controller.text = q.answer3;
      answer4Controller.text = q.answer4;
      hintController.text = q.hintText ?? '';
      correctAnswer = q.correctAnswer;
      selectedCategory = q.category;
      selectedTimeLimit = q.timeLimit;
      selectedLocale = q.locale ?? 'tr';
    } else if (widget.prefillSuggestion != null) {
      final s = widget.prefillSuggestion!;
      questionTextController.text = s.questionText;
      if (s.answers.isNotEmpty) answer1Controller.text = s.answers[0];
      if (s.answers.length > 1) answer2Controller.text = s.answers[1];
      if (s.answers.length > 2) answer3Controller.text = s.answers[2];
      if (s.answers.length > 3) answer4Controller.text = s.answers[3];
      correctAnswer = s.correctAnswer;
      selectedCategory = s.category;
      if (s.hint != null) hintController.text = s.hint!;
      selectedLocale = s.locale ?? 'tr';
    } else {
      selectedLocale = 'tr';
    }
  }

  void disposeMixin() {
    if (!didComplete) {
      AnalyticsManager.instance
          .logEvent(AnalyticsEvents.questionCreateAbandon);
    }
    pageController.dispose();
    questionTextController.dispose();
    answer1Controller.dispose();
    answer2Controller.dispose();
    answer3Controller.dispose();
    answer4Controller.dispose();
    hintController.dispose();
  }

  void onDependenciesChanged() {
    if (!isEditMode && widget.prefillSuggestion == null) {
      final appLocale = Localizations.localeOf(context).languageCode;
      if (AppConstants.supportedQuestionLocales.contains(appLocale)) {
        selectedLocale = appLocale;
      }
    }
  }

  bool canGoNext() {
    switch (currentStep) {
      case 0:
        return questionTextController.text.trim().isNotEmpty;
      case 1:
        return answer1Controller.text.trim().isNotEmpty &&
            answer2Controller.text.trim().isNotEmpty &&
            answer3Controller.text.trim().isNotEmpty &&
            answer4Controller.text.trim().isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void goNext() {
    if (currentStep < 2) {
      setState(() => currentStep++);
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goBack() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> save() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    final data = <String, dynamic>{
      'question_text': questionTextController.text.trim(),
      'correct_answer': correctAnswer,
      'answer_1': answer1Controller.text.trim(),
      'answer_2': answer2Controller.text.trim(),
      'answer_3': answer3Controller.text.trim(),
      'answer_4': answer4Controller.text.trim(),
      'time_limit': selectedTimeLimit,
      'locale': selectedLocale,
      if (selectedCategory != null) 'category': selectedCategory,
      if (hintController.text.trim().isNotEmpty)
        'hint_text': hintController.text.trim(),
    };

    final notifier = ref.read(questionProvider.notifier);

    if (isEditMode) {
      data['order_num'] = widget.editQuestion!.orderNum;
      final result = await notifier.updateQuestion(
        widget.editQuestion!.orderNum,
        data,
      );
      result.when(
        success: (_) => _onSaveSuccess(),
        failure: (f) => _onSaveFailure(f),
      );
    } else {
      final questions = ref.read(questionProvider).valueOrNull ?? [];
      data['order_num'] = questions.length + 1;
      final result = await notifier.createQuestion(data);
      result.when(
        success: (_) => _onSaveSuccess(),
        failure: (f) => _onSaveFailure(f),
      );
    }

    if (mounted) setState(() => isSaving = false);
  }

  void _onSaveSuccess() {
    didComplete = true;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.questionCreateComplete,
      params: {
        if (selectedCategory != null)
          AnalyticsEvents.paramQuestionType: selectedCategory!,
      },
    );
    ref.read(navigationServiceProvider).pop();
  }

  void _onSaveFailure(dynamic f) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('question_save_failed'))),
      );
    }
  }
}
