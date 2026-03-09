import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/features/questions/widgets/question_preview_card.dart';
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
    // Set locale from app locale if not already set from edit/prefill
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
        success: (_) {
          _didComplete = true;
          AnalyticsManager.instance.logEvent(
            AnalyticsEvents.questionCreateComplete,
            params: {
              if (_selectedCategory != null)
                AnalyticsEvents.paramQuestionType: _selectedCategory!,
            },
          );
          ref.read(navigationServiceProvider).pop();
        },
        failure: (f) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(f.toString())),
            );
          }
        },
      );
    } else {
      final questions = ref.read(questionProvider).valueOrNull ?? [];
      data['order_num'] = questions.length + 1;
      final result = await notifier.createQuestion(data);
      result.when(
        success: (_) {
          _didComplete = true;
          AnalyticsManager.instance.logEvent(
            AnalyticsEvents.questionCreateComplete,
            params: {
              if (_selectedCategory != null)
                AnalyticsEvents.paramQuestionType: _selectedCategory!,
            },
          );
          ref.read(navigationServiceProvider).pop();
        },
        failure: (f) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(f.toString())),
            );
          }
        },
      );
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: _isEditMode
          ? context.tr('question_edit_title')
          : context.tr('question_create_title'),
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.md,
            ),
            child: _StepIndicator(
              currentStep: _currentStep,
              labels: [
                context.tr('question_create_step_question'),
                context.tr('question_create_step_answers'),
                context.tr('question_create_step_settings'),
              ],
            ),
          ),

          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepQuestion(theme),
                _buildStepAnswers(theme),
                _buildStepSettings(theme),
              ],
            ),
          ),

          // Preview + Buttons
          Container(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview card
                  QuestionPreviewCard(
                    questionText: _questionTextController.text,
                    answer1: _answer1Controller.text,
                    answer2: _answer2Controller.text,
                    answer3: _answer3Controller.text,
                    answer4: _answer4Controller.text,
                    correctAnswer: _correctAnswer,
                    category: _selectedCategory,
                    timeLimit: _selectedTimeLimit,
                    hintText: _hintController.text,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _goBack,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            child: Text(context.tr('cancel')),
                          ),
                        ),
                      if (_currentStep > 0)
                        const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _isSaving
                              ? null
                              : _currentStep == 2
                                  ? (_canGoNext() ? _save : null)
                                  : (_canGoNext() ? _goNext : null),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                          child: _isSaving
                              ? const AppLoadingWidget.small()
                              : Text(
                                  _currentStep == 2
                                      ? (_isEditMode
                                          ? context.tr(
                                              'question_create_update')
                                          : context.tr(
                                              'question_create_save'))
                                      : context.tr('next'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Question Text + Category ───

  Widget _buildStepQuestion(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                QIcon(QIcons.icWand, size: 28, color: AppColors.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('question_create_motto'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr('question_create_motto_tip'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Question text field
          AppTextField(
            controller: _questionTextController,
            label: context.tr('question'),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Language chip
          Row(
            children: [
              Text(
                context.tr('question_language'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionChip(
                avatar: Text(
                  AppConstants.localeFlagEmojis[_selectedLocale] ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                label: Text(context.tr('locale_$_selectedLocale')),
                onPressed: () async {
                  final result = await showModalBottomSheet<List<String>>(
                    context: context,
                    builder: (_) => LanguagePickerSheet(
                      selectedLanguages: [_selectedLocale],
                      multiSelect: false,
                    ),
                  );
                  if (result != null && result.isNotEmpty) {
                    setState(() => _selectedLocale = result.first);
                  }
                },
                side: BorderSide(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Category selection
          Text(
            context.tr('question_create_select_category'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: AppConstants.questionCategories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return FilterChip(
                selected: isSelected,
                label: Text(context.tr('question_category_$cat')),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? cat : null;
                  });
                },
                selectedColor: AppColors.primarySurface,
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Answers + Correct + Hint ───

  Widget _buildStepAnswers(ThemeData theme) {
    final controllers = [
      _answer1Controller,
      _answer2Controller,
      _answer3Controller,
      _answer4Controller,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 answer fields with radio
          ...List.generate(4, (i) {
            final num = i + 1;
            final isCorrect = _correctAnswer == num;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _correctAnswer = num),
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
                              : AppColors.textHint,
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
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Hint field
          AppTextField(
            controller: _hintController,
            label: context.tr('question_create_hint_label'),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            prefixIcon: QIcon(QIcons.icLightbulb, size: 18, color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Time Preset ───

  Widget _buildStepSettings(ThemeData theme) {
    final timePresets = AppConstants.timePresets;
    final timeLabels = [
      'question_time_fast',
      'question_time_normal',
      'question_time_relaxed',
      'question_time_thoughtful',
    ];
    final timeDescs = [
      'question_time_fast_desc',
      'question_time_normal_desc',
      'question_time_relaxed_desc',
      'question_time_thoughtful_desc',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('question_create_select_time'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2x2 grid of time presets
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.4,
            ),
            itemCount: 4,
            itemBuilder: (_, i) {
              final seconds = timePresets[i];
              final isSelected = _selectedTimeLimit == seconds;
              return _TimePresetCard(
                seconds: seconds,
                label: context.tr(timeLabels[i]),
                description: context.tr(timeDescs[i]),
                isSelected: isSelected,
                onTap: () =>
                    setState(() => _selectedTimeLimit = seconds),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ───

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _StepIndicator({
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepBefore = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepBefore < currentStep
                  ? AppColors.primary
                  : AppColors.border,
            ),
          );
        }
        final step = i ~/ 2;
        final isActive = step == currentStep;
        final isDone = step < currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isDone
                    ? AppColors.primary
                    : AppColors.surface,
                border: Border.all(
                  color: isActive || isDone
                      ? AppColors.primary
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${step + 1}',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              labels[step],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Time Preset Card ───

class _TimePresetCard extends StatelessWidget {
  final int seconds;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimePresetCard({
    required this.seconds,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${seconds}s',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
