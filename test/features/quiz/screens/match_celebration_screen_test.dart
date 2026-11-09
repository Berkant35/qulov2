import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/quiz/screens/match_celebration_screen.dart';
import 'package:qulo_v2/features/quiz/widgets/celebration_stats_card.dart';

/// Kutlama ekranının animasyon + analitik yaşam döngüsü
/// (`MatchCelebrationScreenMixin`): gösterim event'i bir kez atılır, giriş
/// animasyonları sırayla biter ve ekran kapanınca ticker sızıntısı kalmaz.
void main() {
  final events = <(String, Map<String, Object>?)>[];

  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, params) => events.add((name, params));
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  testWidgets('gösterim event\'i, animasyonlar ve temiz kapanış', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: MatchCelebrationScreen(
        matched: true,
        totalCorrect: 3,
        totalQuestions: 3,
        totalTimeSpent: 42,
        powersUsed: 0,
        performanceBadge: 'flawless',
        onStartChat: () {},
        onGoBack: () {},
      ),
    ));
    await tester.pump(); // AppLocalizationsDelegate.load asenkron

    final shown = events.where((e) => e.$1 == AnalyticsEvents.matchCelebrationShown);
    expect(shown, hasLength(1));
    expect(shown.single.$2, {
      AnalyticsEvents.paramMatched: 'true',
      AnalyticsEvents.paramBadge: 'flawless',
    });

    final stats = tester.widget<FadeTransition>(
      find.ancestor(of: find.byType(CelebrationStatsCard), matching: find.byType(FadeTransition)).first,
    );
    expect(stats.opacity.value, 0.0);

    // 200 ms sonra rozet, +600 ms sonra fotoğraf + istatistik başlar.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(stats.opacity.value, 1.0);

    // Kapanış: controller'lar dispose edilmezse TickerProviderStateMixin assert eder.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
