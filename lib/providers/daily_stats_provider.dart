import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';

final dailyStatsProvider = AsyncNotifierProvider<DailyStatsNotifier, DailyStats>(
  DailyStatsNotifier.new,
);

class DailyStatsNotifier extends AsyncNotifier<DailyStats> {
  @override
  Future<DailyStats> build() => fetchStats();

  Future<DailyStats> fetchStats() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.getDailyStats();
    return result.when(
      success: (data) => data,
      failure: (_) {
        final config = ref.read(economyConfigProvider);
        final free = config.limitsFor('free');
        return DailyStats(
          dailyDiscoversUsed: 0,
          dailyDiscoversLimit: free.dailyDiscovers,
          dailyUndosUsed: 0,
          dailyUndosLimit: free.dailyUndos,
          questionsCreated: 0,
          questionsLimit: free.maxQuestions,
          monthlyPurpleBonus: free.monthlyPurpleBonus,
          passportMode: free.passportMode,
          hasAds: free.hasAds,
        );
      },
    );
  }
}
