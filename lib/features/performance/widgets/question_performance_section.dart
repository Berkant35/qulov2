import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';

class QuestionPerformanceSection extends StatelessWidget {
  final QuestionAnalyticsResponse analytics;
  final VoidCallback? onBestQuestionTap;

  const QuestionPerformanceSection({
    super.key,
    required this.analytics,
    this.onBestQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = analytics.totals;
    final questions = analytics.questions;

    if (totals.totalSolveCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('question_performance'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              context.tr('no_solves_yet'),
              style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
            ),
          ),
        ],
      );
    }

    final solvedQuestions = questions.where((q) => q.stats.solveCount > 0).toList();
    final hardestQuestion = solvedQuestions.isNotEmpty
        ? (solvedQuestions..sort((a, b) => a.stats.successRate.compareTo(b.stats.successRate))).first
        : null;

    final bestQuestion = totals.bestQuestionOrder != null
        ? questions.where((q) => q.orderNum == totals.bestQuestionOrder).firstOrNull
        : null;

    final avgTimes = solvedQuestions.map((q) => q.stats.avgTime).where((t) => t > 0);
    final overallAvgTime = avgTimes.isNotEmpty
        ? (avgTimes.reduce((a, b) => a + b) / avgTimes.length).round()
        : 0;

    final diffCounts = <String, int>{};
    for (final q in questions) {
      diffCounts[q.difficultyBadge] = (diffCounts[q.difficultyBadge] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('question_performance'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (bestQuestion != null)
          _QuestionHighlight(
            label: context.tr('best_question'),
            question: bestQuestion,
            color: context.appColors.secondary,
            onTap: onBestQuestionTap,
          ),
        if (hardestQuestion != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _QuestionHighlight(
            label: context.tr('hardest_question'),
            question: hardestQuestion,
            color: context.appColors.error,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _InfoRow(label: context.tr('avg_solve_time'), value: context.fmt.seconds(overallAvgTime)),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('difficulty_distribution'),
          style: theme.textTheme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: diffCounts.entries.map((e) {
            return Chip(
              label: Text('${_difficultyLabel(context, e.key)} (${context.fmt.integer(e.value)})'),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _difficultyLabel(BuildContext context, String badge) {
    return switch (badge) {
      'easy' => context.tr('difficulty_easy'),
      'medium' => context.tr('difficulty_medium'),
      'hard' => context.tr('difficulty_hard'),
      'legendary' => context.tr('difficulty_legendary'),
      _ => context.tr('difficulty_unranked'),
    };
  }
}

class _QuestionHighlight extends StatelessWidget {
  final String label;
  final QuestionAnalyticsItem question;
  final Color color;
  final VoidCallback? onTap;

  const _QuestionHighlight({
    required this.label,
    required this.question,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Q${question.orderNum}: ${question.questionText}',
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${context.fmt.percent(question.stats.successRate)} • ${context.fmt.integer(question.stats.greenEarned)} ${context.tr('green_earned')}',
              style: theme.textTheme.bodySmall?.copyWith(color: context.appColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
