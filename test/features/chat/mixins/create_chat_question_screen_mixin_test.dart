import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/features/chat/mixins/create_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/screens/create_chat_question_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';

import '../../../helpers/fake_chat_repository.dart';
import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Soru gonderimi: kullanici "Gonder"e basip istek surerken geri donerse ekran
/// kapanir. Soru sunucuda YINE olusur (elmas duser) — onbellek, bakiye ve
/// sohbet tazelenmeli; kapali ekranda `ref` StateError atmamali.
class _HostCreate extends CreateChatQuestionScreen {
  const _HostCreate() : super(matchId: 'm1');

  @override
  ConsumerState<CreateChatQuestionScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<CreateChatQuestionScreen>
    with CreateChatQuestionScreenMixin {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

typedef _Harness = ({
  FakeChatRepository chat,
  FakeDiamondRepository diamonds,
  FakeNavigationService nav,
  ProviderContainer container,
  _HostState state,
});

Future<_Harness> _pump(WidgetTester tester) async {
  final chat = FakeChatRepository()..createQuestionGate = Completer<void>();
  final diamonds = FakeDiamondRepository();
  final nav = FakeNavigationService();
  final container = ProviderContainer(overrides: [
    chatRepositoryProvider.overrideWithValue(chat),
    diamondRepositoryProvider.overrideWithValue(diamonds),
    navigationServiceProvider.overrideWithValue(nav),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: _HostCreate()),
  ));
  final state = tester.state<_HostState>(find.byType(_HostCreate))
    ..questionText = 'En sevdigim sehir?'
    ..optionA = 'Izmir'
    ..optionB = 'Ankara';
  return (chat: chat, diamonds: diamonds, nav: nav, container: container, state: state);
}

Future<void> _closeScreen(WidgetTester tester, ProviderContainer container) => tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: SizedBox())),
    );

void main() {
  testWidgets('basari: ekran kapandiysa bile onbellek + bakiye + sohbet tazelenir, pop yok', (tester) async {
    final h = await _pump(tester);
    final messagesBefore = h.chat.getMessagesCalls;

    final submitting = h.state.onSubmit();
    await _closeScreen(tester, h.container);
    h.chat.createQuestionGate!.complete();
    await submitting;
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(h.container.read(chatQuestionCacheProvider).keys, ['q-new']);
    expect(h.diamonds.getBalanceCallCount, 1);
    expect(h.chat.getMessagesCalls, greaterThan(messagesBefore));
    expect(h.nav.pops, 0, reason: 'kapali ekran ikinci kez pop edilmez');
  });

  testWidgets('hata: ekran kapandiysa dogrulama sayfasi / snackbar acilmaz, ref kullanilmaz', (tester) async {
    final h = await _pump(tester);
    h.chat.createQuestionResult = const Failure(ServerFailure(
      code: 'EMAIL_VERIFICATION_REQUIRED',
      message: 'verify',
      statusCode: 403,
    ));

    final submitting = h.state.onSubmit();
    await _closeScreen(tester, h.container);
    h.chat.createQuestionGate!.complete();
    await submitting;

    expect(tester.takeException(), isNull);
    expect(h.nav.sheets, isEmpty);
  });

  testWidgets('acik ekranda basari: soru kaydedilir ve ekran true ile kapanir', (tester) async {
    final h = await _pump(tester);

    final submitting = h.state.onSubmit();
    h.chat.createQuestionGate!.complete();
    await submitting;

    expect(h.container.read(chatQuestionCacheProvider).keys, ['q-new']);
    expect(h.nav.pops, 1);
    expect(h.state.isLoading, isFalse);
  });
}
