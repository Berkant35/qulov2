import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/features/profile/mixins/questions_screen_mixin.dart';
import 'package:qulo_v2/features/profile/widgets/questions_empty_state.dart';
import 'package:qulo_v2/features/profile/widgets/questions_fab.dart';
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
      floatingActionButton: QuestionsFab(onPressed: showModeSheet),
      isLoading: questionsAsync is AsyncLoading || !initialized,
      body: questionsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text(context.tr('error_general'))),
        data: (questions) {
          if (questions.isEmpty) {
            return const QuestionsEmptyState();
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
