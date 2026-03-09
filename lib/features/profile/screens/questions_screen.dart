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
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/pending_changes_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  const QuestionsScreen({super.key});

  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  int _previousCount = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(questionProvider.notifier).fetchQuestions();
      ref.read(pendingChangesProvider.notifier).fetchPending();
    });
  }

  void _checkCelebration(List<QuestionModel> questions) {
    final count = questions.length;
    if (_initialized &&
        _previousCount < AppConstants.minQuestions &&
        count >= AppConstants.minQuestions) {
      _showCelebrationDialog();
    }
    _previousCount = count;
    _initialized = true;
  }

  void _showModeSheet() {
    final questions = ref.read(questionProvider).valueOrNull ?? [];
    if (questions.length >= AppConstants.maxQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('max_questions'))),
      );
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
    ref.read(navigationServiceProvider).push(
      RouteNames.questionCreate,
      extra: question,
    );
  }

  void _deleteQuestion(QuestionModel question) {
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
    if (total < 10) return AppColors.textHint;
    final rate = q.statsCorrect / total;
    if (rate >= 0.8) return AppColors.secondary;
    if (rate >= 0.5) return AppColors.info;
    if (rate >= 0.2) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionProvider);
    final pendingAsync = ref.watch(pendingChangesProvider);
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
          icon: QIcon(QIcons.icChart, size: 22, color: AppColors.textSecondary),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryDark,
        onPressed: _showModeSheet,
        child: const Icon(Icons.add),
      ),
      isLoading: questionsAsync is AsyncLoading,
      body: questionsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (questions) {
          final pendingChanges = pendingAsync.valueOrNull ?? [];

          if (questions.isEmpty && pendingChanges.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QIcon(QIcons.icWand, size: 56, color: AppColors.textHint),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.tr('min_questions'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
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
              // Pending changes section
              if (pendingChanges.isNotEmpty) ...[
                _PendingChangesSection(
                  changes: pendingChanges,
                  onCancel: (id) => ref
                      .read(pendingChangesProvider.notifier)
                      .cancelChange(id),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Question cards
              ...questions.map(
                (q) => _QuestionCard(
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

// ─── Question Card ───

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final String difficultyLabel;
  final Color difficultyColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Dismissible(
        key: ValueKey(question.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(Icons.delete_outline, color: AppColors.error),
        ),
        confirmDismiss: (_) async {
          onDelete();
          return false; // Dialog handles it
        },
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: order number + category + time
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primarySurface,
                      ),
                      child: Center(
                        child: Text(
                          '${question.orderNum}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (question.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          context
                              .tr('question_category_${question.category}'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    if (question.locale != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceInput,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${AppConstants.localeFlagEmojis[question.locale] ?? ''} ${question.locale!.toUpperCase()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceInput,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QIcon(QIcons.icClock,
                              size: 10, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${question.timeLimit}s',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: AppColors.error, size: 18),
                      onPressed: onDelete,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Question text
                Text(
                  question.questionText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Stats row
                Row(
                  children: [
                    Text(
                      '${question.statsSolveCount} ${context.tr('profile_vitrin_solves')}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        difficultyLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: difficultyColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pending Changes Section ───

class _PendingChangesSection extends StatelessWidget {
  final List changes;
  final void Function(String id) onCancel;

  const _PendingChangesSection({
    required this.changes,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QIcon(QIcons.icQueue, size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.tr('pending_changes_title'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('pending_change_info'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...changes.map((change) {
            final isDelete = change.changeType == 'delete';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    isDelete ? Icons.delete_outline : Icons.edit_outlined,
                    size: 16,
                    color: isDelete ? AppColors.error : AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isDelete
                          ? context.tr('pending_change_delete')
                          : context.tr('pending_change_update'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onCancel(change.id),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.tr('pending_change_cancel'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
