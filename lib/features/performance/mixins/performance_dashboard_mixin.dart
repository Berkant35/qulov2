import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/providers/diamond_provider.dart';
import 'package:qulo_v2/providers/question_analytics_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/performance/screens/performance_dashboard_screen.dart';

mixin PerformanceDashboardMixin on ConsumerState<PerformanceDashboardScreen> {
  List<DiamondTransaction> recentTransactions = [];

  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.performanceDashboardOpened);
    Future.microtask(() {
      ref.read(questionAnalyticsProvider.notifier).fetchAnalytics();
      _loadTransactions();
    });
  }

  void disposeMixin() {}

  Future<void> _loadTransactions() async {
    final result = await ref.read(diamondProvider.notifier).fetchHistory();
    if (mounted) {
      setState(() {
        result.when(
          success: (data) => recentTransactions = data.items,
          failure: (_) => recentTransactions = [],
        );
      });
    }
  }

  void onViewAllDiamonds() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.performanceViewAllDiamonds);
    ref.read(navigationServiceProvider).push(RouteNames.diamonds);
  }

  void onBestQuestionTapped() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.performanceBestQuestionTapped);
    ref.read(navigationServiceProvider).push(RouteNames.questionAnalytics);
  }
}
