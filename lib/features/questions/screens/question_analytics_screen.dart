import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/questions/widgets/analytics_totals_section.dart';
import 'package:qulo_v2/features/questions/widgets/best_question_highlight.dart';
import 'package:qulo_v2/features/questions/widgets/question_analytics_card.dart';
import 'package:qulo_v2/providers/question_analytics_provider.dart';

class QuestionAnalyticsScreen extends ConsumerStatefulWidget {
  const QuestionAnalyticsScreen({super.key});

  @override
  ConsumerState<QuestionAnalyticsScreen> createState() =>
      _QuestionAnalyticsScreenState();
}

class _QuestionAnalyticsScreenState
    extends ConsumerState<QuestionAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logEvent(AnalyticsEvents.questionAnalyticsView);
    Future.microtask(
      () => ref.read(questionAnalyticsProvider.notifier).fetchAnalytics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionAnalyticsProvider);
    final analytics = state.valueOrNull;

    return AppScaffold(
      title: context.tr('analytics_title'),
      isLoading: state is AsyncLoading,
      padding: EdgeInsets.zero,
      body: analytics == null
          ? Center(
              child: Text(
                context.tr('analytics_no_data'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnalyticsTotalsSection(totals: analytics.totals),
                  const SizedBox(height: AppSpacing.sectionGap),
                  BestQuestionHighlight(analytics: analytics),
                  if (analytics.totals.bestQuestionOrder != null)
                    const SizedBox(height: AppSpacing.sectionGap),
                  ...analytics.questions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: QuestionAnalyticsCard(item: item),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
