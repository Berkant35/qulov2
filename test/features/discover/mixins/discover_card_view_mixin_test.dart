import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/discover/mixins/discover_card_view_mixin.dart';
import 'package:qulo_v2/features/discover/widgets/discover_card_view.dart';
import 'package:qulo_v2/features/quiz/models/quiz_target_args.dart';
import 'package:qulo_v2/features/quiz/quiz_retry_lock.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

import '../../../helpers/fake_navigation.dart';

/// Keşfet kartı async-gap'leri: beğeni (LIKE) ya da geri alma isteği sürerken
/// kart görünümü ağaçtan çıkarsa (deste yeniden yüklenip boşalır, çıkış)
/// günlük limit paywall'u `ref`, kilit mesajı `context.l10n` ile çöküyordu.
/// Gerçek görünüm ProfileCard (ağ görseli) çizer; aynı mixin host'ta kurulur.
const _card = ProfileCardModel(userId: 'u-2', name: 'Ada', questionCount: 3, photos: ['p.jpg']);

class _HostCard extends DiscoverCardView {
  _HostCard() : super(card: _card, onSwipeRight: () {}, onSwipeLeft: () {});

  @override
  ConsumerState<DiscoverCardView> createState() => _HostState();
}

class _HostState extends ConsumerState<DiscoverCardView>
    with SingleTickerProviderStateMixin, DiscoverCardViewMixin {
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
  Widget build(BuildContext context) => const SizedBox();
}

/// Beğeni / geri alma bir kapıda bekler; sonuç testten verilir (ağ yok).
class _GatedDiscover extends DiscoverNotifier {
  Completer<void>? gate;
  Result<SwipeResponse> swipeResult = const Success(SwipeResponse(matched: false));
  Result<ProfileCardModel> undoResult = const Success(_card);
  final swipes = <String>[];

  @override
  Future<DiscoverState> build() async => const DiscoverState();

  @override
  Future<Result<SwipeResponse>> swipe({required String targetId, required String action}) async {
    swipes.add(targetId);
    await gate?.future;
    return swipeResult;
  }

  @override
  Future<Result<ProfileCardModel>> undoSwipe() async {
    await gate?.future;
    return undoResult;
  }
}

int _statsBuilds = 0;

class _CountingStats extends DailyStatsNotifier {
  @override
  Future<DailyStats> build() async {
    _statsBuilds++;
    return const DailyStats(
      dailyDiscoversUsed: 0,
      dailyDiscoversLimit: 50,
      dailyUndosUsed: 0,
      dailyUndosLimit: 3,
      questionsCreated: 0,
      questionsLimit: 4,
      monthlyPurpleBonus: 0,
      passportMode: false,
      hasAds: true,
    );
  }
}

class _Harness {
  _Harness(this.discover, this.nav, this.container);

  final _GatedDiscover discover;
  final FakeNavigationService nav;
  final ProviderContainer container;
  late _HostState state;
}

Widget _app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: home),
      ),
    );

Future<_Harness> _pump(WidgetTester tester) async {
  final discover = _GatedDiscover()..gate = Completer<void>();
  final nav = FakeNavigationService();
  final container = ProviderContainer(overrides: [
    discoverProvider.overrideWith(() => discover),
    dailyStatsProvider.overrideWith(_CountingStats.new),
    navigationServiceProvider.overrideWithValue(nav),
  ]);
  addTearDown(container.dispose);
  final h = _Harness(discover, nav, container);
  await tester.pumpWidget(_app(container, _HostCard()));
  await tester.pump();
  h.state = tester.state<_HostState>(find.byType(_HostCard));
  return h;
}

/// Kart görünümü ağaçtan çıkar; uygulama kapsamı (container) yaşar.
Future<void> _closeCard(WidgetTester tester, _Harness h) =>
    tester.pumpWidget(_app(h.container, const SizedBox()));

const _dailyLimit = ServerFailure(code: 'DAILY_LIMIT_EXCEEDED', statusCode: 403);
const _retryLocked = ServerFailure(
  code: quizRetryLockedCode,
  statusCode: 409,
  params: {'reason': 'exhausted'},
);

void main() {
  setUp(() {
    _statsBuilds = 0;
    AnalyticsManager.debugEventSink = (_, __) {};
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  group('beğeni sürerken kart görünümü kapanırsa', () {
    testWidgets('günlük limit: paywall açılmaz, ref kullanılmaz', (tester) async {
      final h = await _pump(tester);
      h.discover.swipeResult = const Failure(_dailyLimit);

      final liking = h.state.navigateToQuiz();
      await tester.pump();
      await _closeCard(tester, h);
      h.discover.gate!.complete();
      await liking;

      expect(tester.takeException(), isNull);
      expect(h.discover.swipes, ['u-2']);
      expect(h.nav.sheets, isEmpty);
    });

    testWidgets('kilitli hedef: mesaj için kapalı context kullanılmaz', (tester) async {
      final h = await _pump(tester);
      h.discover.swipeResult = const Failure(_retryLocked);

      final liking = h.state.navigateToQuiz();
      await tester.pump();
      await _closeCard(tester, h);
      h.discover.gate!.complete();
      await liking;

      expect(tester.takeException(), isNull);
    });

    testWidgets('başarı: quiz kapalı görünümden açılmaz', (tester) async {
      final h = await _pump(tester);

      final liking = h.state.navigateToQuiz();
      await tester.pump();
      await _closeCard(tester, h);
      h.discover.gate!.complete();
      await liking;

      expect(tester.takeException(), isNull);
      expect(h.nav.pushes, isEmpty);
    });
  });

  group('açık kartta beğeni sonucu', () {
    testWidgets('başarı: beğenilen profilin quiz\'i açılır', (tester) async {
      final h = await _pump(tester);
      h.discover.gate = null;

      await h.state.navigateToQuiz();

      expect(h.nav.pushes.single.name, RouteNames.quiz);
      expect((h.nav.pushes.single.extra! as QuizTargetArgs).name, 'Ada');
      expect(h.state.isProcessing, isFalse);
    });

    testWidgets('quiz zaten açıkken ikinci dokunuş: LIKE yok, ikinci quiz yok', (tester) async {
      // Crashlytics iOS 2.0.17: geçiş sürerken alttaki yeni kartın çözme düğmesi
      // ikinci quiz'i açtı; global quiz durumu sıfırlanıp `sessionId!` düştü.
      final h = await _pump(tester);
      h.discover.gate = null;
      h.nav.stacked.add(RouteNames.quiz);

      await h.state.navigateToQuiz();

      expect(h.discover.swipes, isEmpty);
      expect(h.nav.pushes, isEmpty);
      expect(h.state.isProcessing, isFalse);
    });

    testWidgets('günlük limit: paywall açılır', (tester) async {
      final h = await _pump(tester);
      h.discover
        ..gate = null
        ..swipeResult = const Failure(_dailyLimit);

      await h.state.navigateToQuiz();

      expect(h.nav.sheets, ['paywall']);
    });
  });

  group('geri alma sürerken kart görünümü kapanırsa', () {
    testWidgets('sunucuda tamamlanan geri alma günlük hak sayacını yine tazeler', (tester) async {
      final h = await _pump(tester);
      await h.container.read(dailyStatsProvider.future);
      expect(_statsBuilds, 1);

      final undoing = h.state.handleUndo();
      await tester.pump();
      await _closeCard(tester, h);
      h.discover.gate!.complete();
      await undoing;
      await h.container.read(dailyStatsProvider.future);

      expect(tester.takeException(), isNull);
      expect(_statsBuilds, 2, reason: 'invalidate edilen sayaç yeniden okunur');
    });

    testWidgets('hata: kapalı görünümde mesaj gösterilmez, hata yutulmaz', (tester) async {
      final h = await _pump(tester);
      h.discover.undoResult = const Failure(_retryLocked);

      final undoing = h.state.handleUndo();
      await tester.pump();
      await _closeCard(tester, h);
      h.discover.gate!.complete();
      await undoing;

      expect(tester.takeException(), isNull);
    });
  });
}
