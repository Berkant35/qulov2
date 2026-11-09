import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/diamonds/models/paywall_triggers.dart';
import 'package:qulo_v2/features/notifications/mixins/push_permission_offer_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_flow_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_power_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/notification_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Paywall zamanlamasi (2.0.18 P2-10): ilk eslesme paywall'i kayittan ~4 dk
/// sonra cikiyordu (Kasim: 39 gosterim, 0 odeme) → kaldirildi. Teklif ihtiyac
/// aninda: kurtarma bakiyesi yetersiz (`quiz_rescue`, guc yolundan ayri).
void main() {
  late List<({String name, Map<String, Object>? params})> events;

  setUp(() {
    // Degerlendirme istemi tamamlanmis: platform kanalina gidilmez.
    SharedPreferences.setMockInitialValues({'qulo_app_review_completed': true});
    events = [];
    AnalyticsManager.debugEventSink = (name, params) => events.add((name: name, params: params));
    AnalyticsForwarder.debugTrackSink = (_, __, ___) {};
    AnalyticsForwarder.instance.setEnabled(false);
  });
  tearDown(() {
    AnalyticsManager.debugEventSink = null;
    AnalyticsForwarder.debugTrackSink = null;
    AnalyticsForwarder.instance.setEnabled(true);
  });

  List<Object?> paywallTriggers() => events
      .where((e) => e.name == AnalyticsEvents.paywallShown || e.name == AnalyticsEvents.paywallView)
      .map((e) => e.params?[AnalyticsEvents.paramTrigger])
      .toList();

  group('eslesme kutlamasindan cikis', () {
    for (final (label, startChat, route) in [
      ('geri don', false, RouteNames.discover),
      ('sohbete basla', true, RouteNames.matches),
    ]) {
      testWidgets('$label: ilk eslesme paywall\'i ACILMAZ, dogrudan $route', (tester) async {
        final h = await _pump(tester, offerPush: false);
        h.state.celebrationMatched = true;

        startChat ? h.state.onStartChat() : h.state.onGoBack();
        await tester.pumpAndSettle();

        expect(h.nav.gos, [route]);
        expect(h.nav.sheets, isNot(contains('premium_suggestion')));
        expect(paywallTriggers(), isEmpty);
      });
    }

    testWidgets('bildirim aciklamasi uygunsa once o, sonra yonlendirme; paywall yok', (tester) async {
      final h = await _pump(tester, offerPush: true);
      h.state.celebrationMatched = true;

      h.state.onGoBack();
      await tester.pumpAndSettle();

      expect(h.nav.sheets, ['push_permission_prompt']);
      expect(h.nav.gos, [RouteNames.discover]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('qulo_app_review_pending_since'), isNotNull,
          reason: 'degerlendirme istemi Kesfet\'e donuse ertelenir');
    });
  });

  group('ihtiyac aninda paywall', () {
    testWidgets('kurtarma bakiyesi yetersiz (403) → trigger quiz_rescue', (tester) async {
      final h = await _pump(tester, offerPush: false);

      final handling = h.state.handlePowerFailure(
        const ServerFailure(code: 'INSUFFICIENT_DIAMONDS', statusCode: 403),
        power: 'SKIP',
        pauseTimer: false,
        paywallTrigger: PaywallTriggers.quizRescue,
      );
      await tester.pump(const Duration(seconds: 2));
      await handling;

      expect(h.nav.sheets, ['paywall']);
      expect(paywallTriggers(), everyElement(PaywallTriggers.quizRescue));
      expect(paywallTriggers(), isNotEmpty);
    });

    testWidgets('soru ici guc bakiyesi yetersiz → varsayilan quiz_power', (tester) async {
      final h = await _pump(tester, offerPush: false);

      final handling = h.state.handlePowerFailure(
        const ServerFailure(code: 'INSUFFICIENT_DIAMONDS', statusCode: 403),
        power: 'HALF',
        pauseTimer: false,
      );
      await tester.pump(const Duration(seconds: 2));
      await handling;

      expect(paywallTriggers(), everyElement(PaywallTriggers.quizPower));
    });
  });
}

class _HostQuiz extends QuizScreen {
  const _HostQuiz() : super(targetId: 'target-1');

  @override
  ConsumerState<QuizScreen> createState() => _QuizState();
}

class _QuizState extends ConsumerState<QuizScreen>
    with QuizScreenStateMixin, PushPermissionOfferMixin<QuizScreen>, QuizPowerMixin, QuizFlowMixin {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('quiz'));
}

class _Notifications extends NotificationNotifier {
  _Notifications(this._offer);
  final bool _offer;

  @override
  Future<bool> shouldOfferPushPrompt() async => _offer;

  @override
  Future<void> markPushPromptShown() async {}
}

Future<({FakeNavigationService nav, _QuizState state})> _pump(
  WidgetTester tester, {
  required bool offerPush,
}) async {
  final nav = FakeNavigationService();
  final container = ProviderContainer(overrides: [
    navigationServiceProvider.overrideWithValue(nav),
    notificationProvider.overrideWith(() => _Notifications(offerPush)),
    exchangeRepositoryProvider.overrideWithValue(FakeExchangeRepository()),
    diamondRepositoryProvider.overrideWithValue(FakeDiamondRepository()),
    userRepositoryProvider.overrideWithValue(FakeUserRepository(const UserModel(id: 'u1', email: 'u1@qulo.test'))),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: [AppLocalizationsDelegate()],
      supportedLocales: [Locale('en')],
      locale: Locale('en'),
      home: _HostQuiz(),
    ),
  ));
  await tester.pumpAndSettle();
  return (nav: nav, state: tester.state<_QuizState>(find.byType(_HostQuiz)));
}
