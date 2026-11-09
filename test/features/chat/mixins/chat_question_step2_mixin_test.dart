import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/features/chat/mixins/chat_question_step2_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/create_chat_question_screen_mixin.dart';
import 'package:qulo_v2/features/chat/screens/create_chat_question_screen.dart';
import 'package:qulo_v2/features/chat/widgets/chat_question_step2.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_chat_repository.dart';

/// Odul fotografi yuklemesi: soru ekrani adimlari kosullu cizer — yukleme
/// surerken "Geri" (adim 1) adim 2'yi dispose eder ama ekran yasar; URL yine
/// ust state'e ulasmali. Tum ekran kapanirsa ustte setState olmamali.
class _HostCreate extends CreateChatQuestionScreen {
  const _HostCreate() : super(matchId: 'm1');

  @override
  ConsumerState<CreateChatQuestionScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<CreateChatQuestionScreen>
    with CreateChatQuestionScreenMixin {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: currentStep == 1
            ? ChatQuestionStep2(
                matchId: widget.matchId,
                timeLimitSeconds: timeLimitSeconds,
                hintText: hintText,
                rewardMediaUrl: rewardMediaUrl,
                rewardMediaType: rewardMediaType,
                hasUnmatchRisk: hasUnmatchRisk,
                hasChatLock: hasChatLock,
                hasPowerBlock: hasPowerBlock,
                onChanged: onStep2Changed,
              )
            : const SizedBox(),
      );
}

class _FakePicker implements ImagePickerManager {
  @override
  Future<PickedImage?> pickFromGallery({double maxWidth = 1080, int imageQuality = 85}) async =>
      PickedImage(bytes: Uint8List(4), mimeType: 'image/jpeg', fileName: 'reward.jpg');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakePicker.${invocation.memberName}');
}

typedef _Harness = ({FakeChatRepository chat, ProviderContainer container, _HostState screen});

Widget _app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: home,
      ),
    );

/// Soru ekrani adim 2'de; odul fotografi secildi, yukleme kapida bekliyor.
Future<(_Harness, Future<void>)> _pumpUploading(WidgetTester tester) async {
  final chat = FakeChatRepository()..questionMediaGate = Completer<void>();
  final container = ProviderContainer(overrides: [
    chatRepositoryProvider.overrideWithValue(chat),
    imagePickerManagerProvider.overrideWithValue(_FakePicker()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(_app(container, const _HostCreate()));
  await tester.pump();
  final screen = tester.state<_HostState>(find.byType(_HostCreate))
    ..questionText = 'En sevdigim sehir?'
    ..optionA = 'Izmir'
    ..optionB = 'Ankara'
    ..onNext();
  await tester.pump();
  final step2 = tester.state(find.byType(ChatQuestionStep2)) as ChatQuestionStep2Mixin;
  final picking = step2.pickPhoto();
  await tester.pump();
  expect(step2.isUploading, isTrue);
  return ((chat: chat, container: container, screen: screen), picking);
}

void main() {
  testWidgets('yukleme surerken Geri (adim 1): ekran yasiyor → URL ust state e ulasir', (tester) async {
    final (h, picking) = await _pumpUploading(tester);

    h.screen.onBack();
    await tester.pump();
    expect(find.byType(ChatQuestionStep2), findsNothing);

    h.chat.questionMediaGate!.complete();
    await picking;
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(h.screen.rewardMediaUrl, 'https://cdn.test/reward.jpg');
    expect(h.screen.rewardMediaType, 'image');
  });

  testWidgets('yukleme surerken tum ekran kapanirsa ustte setState yok', (tester) async {
    final (h, picking) = await _pumpUploading(tester);

    await tester.pumpWidget(_app(h.container, const SizedBox()));
    h.chat.questionMediaGate!.complete();
    await picking;

    expect(tester.takeException(), isNull);
  });

  testWidgets('yukleme hatasi adim 2 kapandiktan sonra gelirse ref / snackbar yok', (tester) async {
    final (h, picking) = await _pumpUploading(tester);
    h.chat.questionMediaResult = const Failure(NetworkFailure());

    h.screen.onBack();
    await tester.pump();
    h.chat.questionMediaGate!.complete();
    await picking;
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SnackBar), findsNothing);
    expect(h.screen.rewardMediaUrl, isNull);
  });
}
