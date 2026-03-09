import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/question_analytics_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class QuestionAnalyticsNotifier extends AsyncNotifier<QuestionAnalyticsResponse?> {
  @override
  Future<QuestionAnalyticsResponse?> build() async => null;

  Future<void> fetchAnalytics() async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getAnalytics();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }
}

final questionAnalyticsProvider =
    AsyncNotifierProvider<QuestionAnalyticsNotifier, QuestionAnalyticsResponse?>(
  QuestionAnalyticsNotifier.new,
);
