import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/mixins/solve_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/screens/solve_chat_question_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_chat_repository.dart';
import '../../../helpers/fake_navigation.dart';

/// Soruyu birakma (abandon): istek surerken ekran kapanirsa hata dalindaki
/// `setState` dispose edilmis State'e dusuyordu ("setState() called after
/// dispose()"; release'te null-check cokmesi).
const _question = ChatQuestionModel(
  id: 'q1',
  matchId: 'm1',
  senderId: 'other',
  questionText: 'En sevdigim sehir?',
  optionA: 'Izmir',
  optionB: 'Ankara',
  createdAt: '2026-10-12T10:00:00Z',
);

class _HostSolve extends SolveChatQuestionScreen {
  const _HostSolve() : super(question: _question, matchId: 'm1');

  @override
  ConsumerState<SolveChatQuestionScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<SolveChatQuestionScreen>
    with SolveChatQuestionScreenMixin {
  @override
  void showRescueSheet() {}

  @override
  Future<void> refreshBalances() async {}

  @override
  Widget build(BuildContext context) => const SizedBox();
}

typedef _Harness = ({
  FakeChatRepository chat,
  FakeNavigationService nav,
  ProviderContainer container,
  _HostState state,
});

Future<_Harness> _pump(WidgetTester tester) async {
  final chat = FakeChatRepository()..answerGate = Completer<void>();
  final nav = FakeNavigationService();
  final container = ProviderContainer(overrides: [
    chatRepositoryProvider.overrideWithValue(chat),
    navigationServiceProvider.overrideWithValue(nav),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: [AppLocalizationsDelegate()],
      supportedLocales: [Locale('en')],
      locale: Locale('en'),
      home: Scaffold(body: _HostSolve()),
    ),
  ));
  // Yerellestirme delegesi asenkron yuklenir; ilk kare ondan sonra kurulur.
  await tester.pump();
  final state = tester.state<_HostState>(find.byType(_HostSolve));
  return (chat: chat, nav: nav, container: container, state: state);
}

Future<void> _closeScreen(WidgetTester tester, ProviderContainer container) => tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: SizedBox())),
    );

void main() {
  testWidgets('birakma hatasi ekran kapandiktan sonra gelirse setState / snackbar yok', (tester) async {
    final h = await _pump(tester);
    h.chat.answerResult = const Failure(NetworkFailure());

    final abandoning = h.state.abandonQuestion();
    await _closeScreen(tester, h.container);
    h.chat.answerGate!.complete();
    await abandoning;

    expect(tester.takeException(), isNull);
  });

  testWidgets('birakma basarisi ekran kapandiktan sonra gelirse ikinci pop yok', (tester) async {
    final h = await _pump(tester);

    final abandoning = h.state.abandonQuestion();
    await _closeScreen(tester, h.container);
    h.chat.answerGate!.complete();
    await abandoning;

    expect(tester.takeException(), isNull);
    expect(h.nav.pops, 0);
  });

  testWidgets('acik ekranda birakma basarisi ekrani NavigationService ile kapatir', (tester) async {
    final h = await _pump(tester);

    final abandoning = h.state.abandonQuestion();
    h.chat.answerGate!.complete();
    await abandoning;

    expect(h.nav.pops, 1);
  });

  testWidgets('acik ekranda birakma hatasi: tekrar denenebilir, hata snackbar ile gosterilir', (tester) async {
    final h = await _pump(tester);
    h.chat.answerResult = const Failure(NetworkFailure());

    final abandoning = h.state.abandonQuestion();
    h.chat.answerGate!.complete();
    await abandoning;
    await tester.pump();

    expect(h.state.isSubmitting, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
