import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile/screens/questions_screen.dart';

mixin QuestionsScreenMixin on ConsumerState<QuestionsScreen> {
  int previousCount = 0;
  bool initialized = false;
  static const keyCelebrationShown = 'celebration_shown';

  void initMixin() {
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

  void checkCelebration(List<QuestionModel> questions) async {
    final count = questions.length;
    if (initialized &&
        previousCount < AppConstants.minQuestions &&
        count >= AppConstants.minQuestions) {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(keyCelebrationShown) ?? false)) {
        await prefs.setBool(keyCelebrationShown, true);
        if (mounted) showCelebrationDialog();
      }
    }
    previousCount = count;
    initialized = true;
  }

  void openAnalytics() {
    ref.read(navigationServiceProvider).push(RouteNames.questionAnalytics);
  }

  void showModeSheet() {
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

  void editQuestion(QuestionModel question) {
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

  void deleteQuestion(QuestionModel question) {
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

  void showCelebrationDialog() {
    final nav = ref.read(navigationServiceProvider);
    nav.showAppDialog(
      CustomDialog(
        name: 'question_celebration',
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Icon(Icons.celebration, size: 64, color: context.appColors.primary),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appColors.primary,
                  ),
                  child: Text(context.tr('question_nudge_celebration_button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String difficultyLabel(QuestionModel q) {
    final total = q.statsCorrect + q.statsWrong;
    if (total < 10) return context.tr('analytics_difficulty_unranked');
    final rate = q.statsCorrect / total;
    if (rate >= 0.8) return context.tr('analytics_difficulty_easy');
    if (rate >= 0.5) return context.tr('analytics_difficulty_medium');
    if (rate >= 0.2) return context.tr('analytics_difficulty_hard');
    return context.tr('analytics_difficulty_legendary');
  }

  Color difficultyColor(QuestionModel q) {
    final total = q.statsCorrect + q.statsWrong;
    if (total < 10) return context.appColors.textHint;
    final rate = q.statsCorrect / total;
    if (rate >= 0.8) return context.appColors.secondary;
    if (rate >= 0.5) return context.appColors.info;
    if (rate >= 0.2) return context.appColors.warning;
    return context.appColors.error;
  }
}
