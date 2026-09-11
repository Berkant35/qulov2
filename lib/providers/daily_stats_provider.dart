import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

final dailyStatsProvider = AsyncNotifierProvider<DailyStatsNotifier, DailyStats>(
  DailyStatsNotifier.new,
);

/// Sunucuyla ayni esik (qulo-server `subscription.service.ts` UNLIMITED_THRESHOLD):
/// config'te >= 999999 sinirsiz demektir ve -1 olarak tasinir.
const _unlimitedThreshold = 999999;

int _limitOrUnlimited(int value) => value >= _unlimitedThreshold ? -1 : value;

class DailyStatsNotifier extends AsyncNotifier<DailyStats> {
  @override
  Future<DailyStats> build() => fetchStats();

  Future<DailyStats> fetchStats() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final result = await repo.getDailyStats();
    return result.when(
      success: (data) => data,
      failure: (_) => _fallbackForKnownPlan(),
    );
  }

  /// Istek basarisizsa bilinen aboneligin limitleri. Eskiden her zaman
  /// ucretsiz limitler donuyor ve onbellekte kaliyordu: tek bir gecici hata
  /// Premium kullaniciya 4 soru slotu ve kilitli geri alma gosterirdi.
  /// Abonelik henuz bilinmiyorsa ucretsize duser (sunucu zaten zorluyor).
  DailyStats _fallbackForKnownPlan() {
    final subscription = ref.read(subscriptionProvider).valueOrNull;
    final plan = (subscription?.isActive ?? false) ? subscription!.plan : 'free';
    final limits = ref.read(economyConfigProvider).limitsFor(plan);
    return DailyStats(
      dailyDiscoversUsed: 0,
      dailyDiscoversLimit: _limitOrUnlimited(limits.dailyDiscovers),
      dailyUndosUsed: 0,
      dailyUndosLimit: _limitOrUnlimited(limits.dailyUndos),
      questionsCreated: 0,
      questionsLimit: limits.maxQuestions,
      monthlyPurpleBonus: limits.monthlyPurpleBonus,
      passportMode: limits.passportMode,
      hasAds: limits.hasAds,
    );
  }
}
