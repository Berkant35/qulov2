import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

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
      failure: (_) => const DailyStats(
        dailyDiscoversUsed: 0,
        dailyDiscoversLimit: 50,
        dailyUndosUsed: 0,
        dailyUndosLimit: 0,
        questionsCreated: 0,
        questionsLimit: 4,
        monthlyPurpleBonus: 0,
        passportMode: false,
        hasAds: true,
      ),
    );
  }
}
