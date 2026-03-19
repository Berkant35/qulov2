import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/features/questions/widgets/step_indicator.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_question.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_answers.dart';
import 'package:qulo_v2/features/questions/widgets/question_step_settings.dart';
import 'package:qulo_v2/features/questions/widgets/question_create_bottom_bar.dart';
import 'package:qulo_v2/providers/question_provider.dart';

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

class _QuestionCreateScreenState extends ConsumerState<QuestionCreateScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  final _questionTextController = TextEditingController();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _answer3Controller = TextEditingController();
  final _answer4Controller = TextEditingController();
  final _hintController = TextEditingController();
  int _correctAnswer = 1;
  String? _selectedCategory;
  int _selectedTimeLimit = 30;
  late String _selectedLocale;

  bool get _isEditMode => widget.editQuestion != null;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logEvent(AnalyticsEvents.questionCreateStart);
    if (_isEditMode) {
      final q = widget.editQuestion!;
      _questionTextController.text = q.questionText;
      _answer1Controller.text = q.answer1;
      _answer2Controller.text = q.answer2;
      _answer3Controller.text = q.answer3;
      _answer4Controller.text = q.answer4;
      _hintController.text = q.hintText ?? '';
      _correctAnswer = q.correctAnswer;
      _selectedCategory = q.category;
      _selectedTimeLimit = q.timeLimit;
      _selectedLocale = q.locale ?? 'tr';
    } else if (widget.prefillSuggestion != null) {
      final s = widget.prefillSuggestion!;
      _questionTextController.text = s.questionText;
      if (s.answers.isNotEmpty) _answer1Controller.text = s.answers[0];
      if (s.answers.length > 1) _answer2Controller.text = s.answers[1];
      if (s.answers.length > 2) _answer3Controller.text = s.answers[2];
      if (s.answers.length > 3) _answer4Controller.text = s.answers[3];
      _correctAnswer = s.correctAnswer;
      _selectedCategory = s.category;
      if (s.hint != null) _hintController.text = s.hint!;
      _selectedLocale = 'tr';
    } else {
      _selectedLocale = 'tr';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEditMode && widget.prefillSuggestion == null) {
      final appLocale = Localizations.localeOf(context).languageCode;
      if (AppConstants.supportedQuestionLocales.contains(appLocale)) {
        _selectedLocale = appLocale;
      }
    }
  }

  @override
  void dispose() {
    if (!_didComplete) {
      AnalyticsManager.instance.logEvent(AnalyticsEvents.questionCreateAbandon);
    }
    _pageController.dispose();
    _questionTextController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _answer3Controller.dispose();
    _answer4Controller.dispose();
    _hintController.dispose();
    super.dispose();
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 0:
        return _questionTextController.text.trim().isNotEmpty;
      case 1:
        return _answer1Controller.text.trim().isNotEmpty &&
            _answer2Controller.text.trim().isNotEmpty &&
            _answer3Controller.text.trim().isNotEmpty &&
            _answer4Controller.text.trim().isNotEmpty;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _goNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'question_text': _questionTextController.text.trim(),
      'correct_answer': _correctAnswer,
      'answer_1': _answer1Controller.text.trim(),
      'answer_2': _answer2Controller.text.trim(),
      'answer_3': _answer3Controller.text.trim(),
      'answer_4': _answer4Controller.text.trim(),
      'time_limit': _selectedTimeLimit,
      'locale': _selectedLocale,
      if (_selectedCategory != null) 'category': _selectedCategory,
      if (_hintController.text.trim().isNotEmpty)
        'hint_text': _hintController.text.trim(),
    };

    final notifier = ref.read(questionProvider.notifier);

    if (_isEditMode) {
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

    if (mounted) setState(() => _isSaving = false);
  }

  void _onSaveSuccess() {
    _didComplete = true;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.questionCreateComplete,
      params: {
        if (_selectedCategory != null)
          AnalyticsEvents.paramQuestionType: _selectedCategory!,
      },
    );
    ref.read(navigationServiceProvider).pop();
  }

  void _onSaveFailure(dynamic f) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditMode
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
              currentStep: _currentStep,
              labels: [
                context.tr('question_create_step_question'),
                context.tr('question_create_step_answers'),
                context.tr('question_create_step_settings'),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                QuestionStepQuestion(
                  questionTextController: _questionTextController,
                  selectedLocale: _selectedLocale,
                  selectedCategory: _selectedCategory,
                  onLocaleChanged: (v) => setState(() => _selectedLocale = v),
                  onCategoryChanged: (v) => setState(() => _selectedCategory = v),
                ),
                QuestionStepAnswers(
                  answer1Controller: _answer1Controller,
                  answer2Controller: _answer2Controller,
                  answer3Controller: _answer3Controller,
                  answer4Controller: _answer4Controller,
                  hintController: _hintController,
                  correctAnswer: _correctAnswer,
                  onCorrectAnswerChanged: (v) => setState(() => _correctAnswer = v),
                ),
                QuestionStepSettings(
                  selectedTimeLimit: _selectedTimeLimit,
                  onTimeLimitChanged: (v) => setState(() => _selectedTimeLimit = v),
                ),
              ],
            ),
          ),
          QuestionCreateBottomBar(
            questionTextController: _questionTextController,
            answer1Controller: _answer1Controller,
            answer2Controller: _answer2Controller,
            answer3Controller: _answer3Controller,
            answer4Controller: _answer4Controller,
            hintController: _hintController,
            correctAnswer: _correctAnswer,
            selectedCategory: _selectedCategory,
            selectedTimeLimit: _selectedTimeLimit,
            currentStep: _currentStep,
            isSaving: _isSaving,
            isEditMode: _isEditMode,
            canGoNext: _canGoNext(),
            onBack: _goBack,
            onNext: _goNext,
            onSave: _save,
          ),
        ],
      ),
    );
  }
}
