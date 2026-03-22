import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/performance/mixins/performance_dashboard_mixin.dart';
import 'package:qulo_v2/features/performance/widgets/diamond_economy_section.dart';
import 'package:qulo_v2/features/performance/widgets/performance_summary_grid.dart';
import 'package:qulo_v2/features/performance/widgets/question_performance_section.dart';
import 'package:qulo_v2/providers/question_analytics_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen>
    with PerformanceDashboardMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(questionAnalyticsProvider);
    final analytics = analyticsState.valueOrNull;
    final user = ref.watch(userProvider).valueOrNull;

    return AppScaffold(
      title: context.tr('performance_dashboard'),
      isLoading: analyticsState is AsyncLoading,
      padding: EdgeInsets.zero,
      body: analytics == null
          ? Center(
              child: Text(
                context.tr('no_data_yet'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PerformanceSummaryGrid(totals: analytics.totals),
                  const SizedBox(height: AppSpacing.sectionGap),
                  DiamondEconomySection(
                    greenBalance: user?.greenDiamonds ?? 0,
                    purpleBalance: user?.purpleDiamonds ?? 0,
                    recentTransactions: recentTransactions,
                    onViewAll: onViewAllDiamonds,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  QuestionPerformanceSection(
                    analytics: analytics,
                    onBestQuestionTap: onBestQuestionTapped,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
    );
  }
}
