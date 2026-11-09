import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/features/chat/mixins/draft_history_sheet_mixin.dart';
import 'package:qulo_v2/features/chat/sheets/draft_history_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../../../helpers/fake_chat_repository.dart';

/// Taslak silme: kaydirilan taslak sunucu cevabi beklenmeden listeden cikar
/// (Dismissible sozlesmesi); sheet istek surerken kapanirsa setState yok.
const _drafts = [
  ChatQuestionDraftModel(
    id: 'd1',
    questionText: 'Ilk taslak?',
    optionA: 'A',
    optionB: 'B',
    correctOption: 'A',
    createdAt: '2026-10-12T10:00:00Z',
  ),
  ChatQuestionDraftModel(
    id: 'd2',
    questionText: 'Ikinci taslak?',
    optionA: 'A',
    optionB: 'B',
    correctOption: 'B',
    createdAt: '2026-10-12T10:01:00Z',
  ),
];

typedef _Harness = ({FakeChatRepository chat, ProviderContainer container});

Future<_Harness> _pump(WidgetTester tester) async {
  final chat = FakeChatRepository()
    ..drafts = [..._drafts]
    ..deleteDraftGate = Completer<void>();
  final container = ProviderContainer(overrides: [
    chatRepositoryProvider.overrideWithValue(chat),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(body: DraftHistorySheet(onDraftSelected: (_) {})),
    ),
  ));
  await tester.pumpAndSettle();
  return (chat: chat, container: container);
}

DraftHistorySheetMixin _sheet(WidgetTester tester) =>
    tester.state(find.byType(DraftHistorySheet)) as DraftHistorySheetMixin;

void main() {
  testWidgets('kaydirilan taslak sunucu cevabi beklenmeden listeden cikar', (tester) async {
    final h = await _pump(tester);

    unawaited(_sheet(tester).deleteDraft('d1'));
    await tester.pump();

    expect(_sheet(tester).drafts!.map((d) => d.id), ['d2']);
    expect(find.text('Ilk taslak?'), findsNothing);
    expect(h.chat.deletedDraftIds, ['d1']);
    h.chat.deleteDraftGate!.complete();
  });

  testWidgets('silme depodan gelen listeyi yerinde degistirmez', (tester) async {
    final h = await _pump(tester);

    unawaited(_sheet(tester).deleteDraft('d1'));
    await tester.pump();

    expect(h.chat.drafts.map((d) => d.id), ['d1', 'd2']);
    h.chat.deleteDraftGate!.complete();
  });

  testWidgets('silme HATASI sheet kapandiktan sonra gelirse snackbar / context yok', (tester) async {
    final h = await _pump(tester);
    h.chat.deleteDraftResult = const Failure(NetworkFailure());

    final deleting = _sheet(tester).deleteDraft('d1');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: h.container,
      child: const MaterialApp(home: SizedBox()),
    ));
    h.chat.deleteDraftGate!.complete();
    await deleting;

    expect(tester.takeException(), isNull);
  });

  testWidgets('silme basarisi sheet kapandiktan sonra gelirse setState yok', (tester) async {
    final h = await _pump(tester);

    final deleting = _sheet(tester).deleteDraft('d1');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: h.container,
      child: const MaterialApp(home: SizedBox()),
    ));
    h.chat.deleteDraftGate!.complete();
    await deleting;

    expect(tester.takeException(), isNull);
  });

  testWidgets('silme hatasi: snackbar gosterilir', (tester) async {
    final h = await _pump(tester);
    h.chat.deleteDraftResult = const Failure(NetworkFailure());

    final deleting = _sheet(tester).deleteDraft('d1');
    h.chat.deleteDraftGate!.complete();
    await deleting;
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
