import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/features/profile/mixins/questions_screen_mixin.dart';
import 'package:qulo_v2/features/profile/widgets/questions_list_card.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({super.key});

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen>
    with QuestionsScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<List<QuestionModel>>>(questionProvider, (_, next) {
      next.whenData((questions) => checkCelebration(questions));
    });

    return AppScaffold(
      title: context.tr('my_questions'),
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          onPressed: () {},
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
            backgroundColor: isAtLimit
                ? context.appColors.textHint
                : context.appColors.primaryDark,
            onPressed: showModeSheet,
            child: isAtLimit
                ? QIcon(QIcons.icLock, size: 22, color: Colors.white)
                : const Icon(Icons.add),
          );
        },
      ),
      isLoading: questionsAsync is AsyncLoading || !initialized,
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
                      context.tr('min_questions').replaceAll(
                          '{count}', '${AppConstants.minQuestions}'),
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
              ...questions.map(
                (q) => QuestionsListCard(
                  question: q,
                  difficultyLabel: difficultyLabel(q),
                  difficultyColor: difficultyColor(q),
                  onTap: () => editQuestion(q),
                  onDelete: () => deleteQuestion(q),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
