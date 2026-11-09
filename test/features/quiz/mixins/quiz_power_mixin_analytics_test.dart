import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_forwarder.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/quiz_model.dart';
import 'package:qulo_v2/data/repositories/chat_repository.dart';
import 'package:qulo_v2/data/repositories/quiz_repository.dart';
import 'package:qulo_v2/features/chat/mixins/chat_question_power_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/solve_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/screens/solve_chat_question_screen.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_power_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/quiz_screen_state_mixin.dart';
import 'package:qulo_v2/features/quiz/screens/quiz_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';

import '../../../helpers/fake_repositories.dart';

typedef _Logged = ({String name, Map<String, Object>? params});
typedef _Forwarded = ({String name, String? category, Map<String, dynamic>? metadata});

/// Spec §9.3 + §13.5/14: gerçek quiz'in `quiz_power_tap` / `quiz_power_used` olayları
/// Firebase'e ek olarak `flow_events`'e de gider (`FunnelEvents.logAuthed`); parametreler
/// aynı kalır. Yönlendirme yalnız bu çağrı noktalarında AÇIKÇA yapılır — `AnalyticsManager`'a
/// önek/wildcard allow-list konmaz, çünkü `chat_power_*` olayları da sızardı.
void main() {
  late List<_Logged> firebase;
  late List<_Forwarded> forwarded;

  setUp(() {
    firebase = [];
    forwarded = [];
    AnalyticsManager.debugEventSink =
        (name, params) => firebase.add((name: name, params: params));
    AnalyticsForwarder.debugTrackSink = (name, category, metadata) =>
        forwarded.add((name: name, category: category, metadata: metadata));
    // logAuthed AnalyticsForwarder'a da yazar (15 sn'lik zamanlayıcı kurar).
    AnalyticsForwarder.instance.setEnabled(false);
  });

  tearDown(() {
    AnalyticsManager.debugEventSink = null;
    AnalyticsForwarder.debugTrackSink = null;
    AnalyticsForwarder.instance.setEnabled(true);
  });

  List<String> names(List<_Logged> l) => l.map((e) => e.name).toList();
  List<String> fwdNames() => forwarded.map((e) => e.name).toList();

  group('quiz gücü', () {
    testWidgets('quiz_power_tap ve quiz_power_used Firebase + flow_events\'e gider, parametreler aynı',
        (tester) async {
      final h = await _pumpQuiz(tester);

      await h.state.usePower('HALF');

      expect(names(firebase), [AnalyticsEvents.quizPowerTap, AnalyticsEvents.quizPowerUsed]);
      expect(fwdNames(), [AnalyticsEvents.quizPowerTap, AnalyticsEvents.quizPowerUsed],
          reason: 'forwarder çağrısı = flow_events yönlendirmesi');

      // flow_events kopyası Firebase'dekiyle birebir aynı parametreleri taşır.
      for (var i = 0; i < 2; i++) {
        expect(forwarded[i].metadata, firebase[i].params);
        expect(forwarded[i].category, 'funnel');
      }
      expect(firebase[0].params, {
        AnalyticsEvents.paramPower: 'HALF',
        AnalyticsEvents.paramHasInventory: false,
        AnalyticsEvents.paramCost: 40,
      });
      expect(firebase[1].params, {
        AnalyticsEvents.paramPower: 'HALF',
        AnalyticsEvents.paramSource: AnalyticsEvents.sourceDiamond,
        AnalyticsEvents.paramPurpleSpent: 40,
      });
    });

    testWidgets('rescue yolundaki quiz_power_used da flow_events\'e gider; quiz_rescue_accepted gitmez',
        (tester) async {
      final h = await _pumpQuiz(tester);

      await h.state.onRescue('SKIP');

      expect(names(firebase), [AnalyticsEvents.quizRescueAccepted, AnalyticsEvents.quizPowerUsed]);
      expect(fwdNames(), [AnalyticsEvents.quizPowerUsed],
          reason: 'yalnız tap/used yönlendirilir; rescue_accepted Firebase\'de kalır');
      expect(forwarded.single.metadata, firebase[1].params);
      expect(firebase[1].params, {
        AnalyticsEvents.paramPower: 'SKIP',
        AnalyticsEvents.paramSource: AnalyticsEvents.sourceDiamond,
        AnalyticsEvents.paramPurpleSpent: 60,
      });
    });

    testWidgets('quiz_power_failed yönlendirilmez (kapsam yalnız tap/used)', (tester) async {
      final h = await _pumpQuiz(tester);
      h.repo.answerResult = const Failure(ServerFailure(code: 'POWER_ALREADY_USED'));

      await h.state.usePower('HALF');

      expect(names(firebase), [AnalyticsEvents.quizPowerTap, AnalyticsEvents.quizPowerFailed]);
      expect(fwdNames(), [AnalyticsEvents.quizPowerTap]);
    });
  });

  group('sohbet gücü (değişmez)', () {
    testWidgets('chat_power_tap / chat_power_used yalnız Firebase\'e gider, flow_events\'e sızmaz',
        (tester) async {
      final h = await _pumpChat(tester);

      await h.state.usePower('HALF');

      expect(names(firebase), [AnalyticsEvents.chatPowerTap, AnalyticsEvents.chatPowerUsed]);
      expect(forwarded, isEmpty, reason: 'sohbet olayları forwarder\'a gitmez');
      expect(firebase[1].params, {
        AnalyticsEvents.paramPower: 'HALF',
        AnalyticsEvents.paramSource: AnalyticsEvents.sourceDiamond,
        AnalyticsEvents.paramPurpleSpent: 25,
      });
    });
  });
}

// ─── Quiz harness ──────────────────────────────────────────────────────────

class _HostQuiz extends QuizScreen {
  const _HostQuiz() : super(targetId: 'target-1');

  @override
  ConsumerState<QuizScreen> createState() => _QuizState();
}

class _QuizState extends ConsumerState<QuizScreen> with QuizScreenStateMixin, QuizPowerMixin {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('quiz'));
}

Widget _app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: home,
      ),
    );

typedef _QuizHarness = ({_FakeQuizRepository repo, _QuizState state});

Future<_QuizHarness> _pumpQuiz(WidgetTester tester) async {
  final repo = _FakeQuizRepository();
  final container = ProviderContainer(overrides: [
    quizRepositoryProvider.overrideWithValue(repo),
    exchangeRepositoryProvider.overrideWithValue(FakeExchangeRepository()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(_app(container, const _HostQuiz()));
  await tester.pumpAndSettle();
  // Oturum + soru yüklü: fiyatlar `quizProvider.powerCosts`'tan okunur.
  await container.read(quizProvider.notifier).startSession('target-1');
  return (repo: repo, state: tester.state<_QuizState>(find.byType(_HostQuiz)));
}

class _FakeQuizRepository implements QuizRepository {
  /// Güç yanıtı: cevap beklenen oturum (HALF iki şık eler).
  Result<QuizAnswerResponse> answerResult = const Success(QuizAnswerResponse(
    awaitingAnswer: true,
    powerResult: {
      'removed_indices': [0, 1],
    },
  ));

  /// Rescue yanıtı: oturum sürüyor (kutlama ekranı yok).
  Result<QuizAnswerResponse> rescueResult =
      const Success(QuizAnswerResponse(sessionStatus: 'IN_PROGRESS'));

  @override
  Future<Result<QuizStartResponse>> startSession(String targetId) async => const Success(
        QuizStartResponse(
          sessionId: 's1',
          totalQuestions: 3,
          powerCosts: {
            'HALF': SessionPowerCost(purple: 40, green: 0),
            'SKIP': SessionPowerCost(purple: 60, green: 0),
          },
        ),
      );

  @override
  Future<Result<QuizQuestionModel>> getCurrentQuestion(String sessionId) async => const Success(
        QuizQuestionModel(
          sessionId: 's1',
          questionNumber: 1,
          totalQuestions: 3,
          questionId: 'q1',
          questionText: 'Soru?',
          answers: [
            QuizAnswerOption(index: 0, text: 'A'),
            QuizAnswerOption(index: 1, text: 'B'),
            QuizAnswerOption(index: 2, text: 'C'),
            QuizAnswerOption(index: 3, text: 'D'),
          ],
        ),
      );

  @override
  Future<Result<QuizAnswerResponse>> answerQuestion(
    String sessionId, {
    int? selectedAnswer,
    String? powerUsed,
    int? timeSpent,
  }) async =>
      answerResult;

  @override
  Future<Result<QuizAnswerResponse>> rescueWithSkip(String sessionId,
          {String powerType = 'SKIP'}) async =>
      rescueResult;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeQuizRepository.${invocation.memberName}');
}

// ─── Chat harness ──────────────────────────────────────────────────────────

const _question = ChatQuestionModel(
  id: 'q1',
  matchId: 'm1',
  senderId: 'other',
  questionText: 'En sevdigim sehir?',
  optionA: 'Izmir',
  optionB: 'Ankara',
  createdAt: '2026-10-12T10:00:00Z',
);

class _HostChat extends SolveChatQuestionScreen {
  const _HostChat() : super(question: _question, matchId: 'm1');

  @override
  ConsumerState<SolveChatQuestionScreen> createState() => _ChatState();
}

class _ChatState extends ConsumerState<SolveChatQuestionScreen>
    with SolveChatQuestionScreenMixin, ChatQuestionPowerMixin {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('chat'));
}

typedef _ChatHarness = ({_ChatState state});

Future<_ChatHarness> _pumpChat(WidgetTester tester) async {
  final container = ProviderContainer(overrides: [
    chatRepositoryProvider.overrideWithValue(_FakeChatRepository()),
    exchangeRepositoryProvider.overrideWithValue(FakeExchangeRepository()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(_app(container, const _HostChat()));
  await tester.pumpAndSettle();
  return (state: tester.state<_ChatState>(find.byType(_HostChat)));
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<Result<UsePowerResponse>> usePower(String questionId, String powerName) async =>
      const Success(UsePowerResponse(cost: 25, eliminatedOptions: ['B']));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeChatRepository.${invocation.memberName}');
}
