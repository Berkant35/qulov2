import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile/widgets/questions_list_card.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({super.key});

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  int _previousCount = 0;
  bool _initialized = false;
  static const _keyCelebrationShown = 'celebration_shown';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(questionProvider.notifier).fetchQuestions();
      final questions = ref.read(questionProvider).valueOrNull ?? [];
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.questionListView,
        params: {
          AnalyticsEvents.paramQuestionsCount: questions.length,
        },
      );
    });
  }

  void _checkCelebration(List<QuestionModel> questions) async {
    final count = questions.length;
    if (_initialized &&
        _previousCount < AppConstants.minQuestions &&
        count >= AppConstants.minQuestions) {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(_keyCelebrationShown) ?? false)) {
        await prefs.setBool(_keyCelebrationShown, true);
        if (mounted) _showCelebrationDialog();
      }
    }
    _previousCount = count;
    _initialized = true;
  }

  void _showModeSheet() {
    final questions = ref.read(questionProvider).valueOrNull ?? [];
    final dailyStats = ref.read(dailyStatsProvider).valueOrNull;
    final questionsLimit = dailyStats?.questionsLimit ?? 4;
    if (questions.length >= questionsLimit) {
      PaywallBottomSheetContent.show(ref, trigger: 'question_limit');
      return;
    }

    final nav = ref.read(navigationServiceProvider);
    nav.showAppBottomSheet(
      ListBottomSheet<String>(
        name: 'question_mode_select',
        title: context.tr('question_mode_title'),
        options: [
          SheetOption(
            icon: Icons.auto_awesome,
            label: context.tr('question_create_easy_mode'),
            value: 'easy',
          ),
          SheetOption(
            icon: Icons.edit_note,
            label: context.tr('question_create_advanced_mode'),
            value: 'advanced',
          ),
        ],
      ),
    ).then((value) {
      if (value == null) return;
      if (value == 'easy') {
        nav.push(RouteNames.questionEasyMode);
      } else {
        nav.push(RouteNames.questionCreate);
      }
    });
  }

  void _editQuestion(QuestionModel question) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.questionEdit,
      params: {
        AnalyticsEvents.paramQuestionId: question.id,
      },
    );
    ref.read(navigationServiceProvider).push(
      RouteNames.questionCreate,
      extra: question,
    );
  }

  void _deleteQuestion(QuestionModel question) {
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.questionDelete,
      params: {
        AnalyticsEvents.paramQuestionId: question.id,
      },
    );
    final nav = ref.read(navigationServiceProvider);
    nav.showAppDialog(
      ConfirmDialog(
        name: 'delete_question',
        title: context.tr('delete'),
        message: question.questionText,
        confirmText: context.tr('delete'),
        isDestructive: true,
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(questionProvider.notifier).deleteQuestion(question.orderNum);
      }
    });
  }

  void _showCelebrationDialog() {
    final nav = ref.read(navigationServiceProvider);
    nav.showAppDialog(
      CustomDialog(
        name: 'question_celebration',
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Icon(Icons.celebration, size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('question_nudge_celebration_title'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    nav.closeOverlay();
                    ref.read(navigationServiceProvider).go(RouteNames.discover);
                  },
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child:
                      Text(context.tr('question_nudge_celebration_button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _difficultyLabel(QuestionModel q) {
    final total = q.statsCorrect + q.statsWrong;
    if (total < 10) return context.tr('analytics_difficulty_unranked');
    final rate = q.statsCorrect / total;
    if (rate >= 0.8) return context.tr('analytics_difficulty_easy');
    if (rate >= 0.5) return context.tr('analytics_difficulty_medium');
    if (rate >= 0.2) return context.tr('analytics_difficulty_hard');
    return context.tr('analytics_difficulty_legendary');
  }

  Color _difficultyColor(QuestionModel q) {
    final total = q.statsCorrect + q.statsWrong;
    if (total < 10) return context.appColors.textHint;
    final rate = q.statsCorrect / total;
    if (rate >= 0.8) return AppColors.secondary;
    if (rate >= 0.5) return AppColors.info;
    if (rate >= 0.2) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionProvider);
    final theme = Theme.of(context);

    // Check for celebration when questions data changes
    ref.listen<AsyncValue<List<QuestionModel>>>(questionProvider, (_, next) {
      next.whenData((questions) => _checkCelebration(questions));
    });

    return AppScaffold(
      title: context.tr('my_questions'),
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Navigate to analytics screen when implemented
          },
          icon: QIcon(QIcons.icChart, size: 22, color: context.appColors.textSecondary),
        ),
      ],
      floatingActionButton: Builder(
        builder: (context) {
          final questions = questionsAsync.valueOrNull ?? [];
          final dailyStats = ref.watch(dailyStatsProvider).valueOrNull;
          final questionsLimit = dailyStats?.questionsLimit ?? 4;
          final isAtLimit = questions.length >= questionsLimit;

          return FloatingActionButton(
            backgroundColor: isAtLimit ? context.appColors.textHint : AppColors.primaryDark,
            onPressed: _showModeSheet,
            child: isAtLimit
                ? QIcon(QIcons.icLock, size: 22, color: Colors.white)
                : const Icon(Icons.add),
          );
        },
      ),
      isLoading: questionsAsync is AsyncLoading,
      body: questionsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text(context.tr('error_general'))),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QIcon(QIcons.icWand, size: 56, color: context.appColors.textHint),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.tr('min_questions'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              // Question cards
              ...questions.map(
                (q) => QuestionsListCard(
                  question: q,
                  difficultyLabel: _difficultyLabel(q),
                  difficultyColor: _difficultyColor(q),
                  onTap: () => _editQuestion(q),
                  onDelete: () => _deleteQuestion(q),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
