import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/data/repositories/block_repository.dart';
import 'package:qulo_v2/features/chat/mixins/chat_media_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/chat_moderation_mixin.dart';
import 'package:qulo_v2/features/chat/mixins/chat_screen_mixin.dart';
import 'package:qulo_v2/features/chat/screens/chat_screen.dart';
import 'package:qulo_v2/features/notifications/mixins/push_permission_offer_mixin.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';

import '../../../helpers/fake_chat_repository.dart';
import '../../../helpers/fake_navigation.dart';

/// Sohbet ekrani async-gap'leri: kullanici istek surerken geri donerse State
/// dispose olur ve `ref` "Cannot use ref after the widget was disposed"
/// (StateError) atar. Gercek `ChatScreen` Supabase realtime ister; ayni mixin
/// zinciri (ChatScreen + Media + Moderation; realtime kancalari bos) bir host
/// ekranda kurulur.
class _HostChat extends ChatScreen {
  const _HostChat({super.key, super.matchId = 'm1'});

  @override
  ConsumerState<ChatScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<ChatScreen>
    with
        PushPermissionOfferMixin<ChatScreen>,
        ChatScreenMixin,
        ChatMediaMixin,
        ChatModerationMixin {
  @override
  void subscribeRealtime() {}

  @override
  void disposeRealtime() {}

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

/// Eslesme listesi yuklu: sohbetin karsi tarafi `u-other`.
class _SeededMatches extends MatchListNotifier {
  @override
  Future<List<MatchModel>> build() async => const [
        MatchModel(
          matchId: 'm1',
          matchedAt: '2026-10-01T00:00:00Z',
          user: MatchUserModel(userId: 'u-other'),
        ),
      ];
}

class _FakeBlocks implements BlockRepository {
  final blocked = <String>[];

  @override
  Future<Result<void>> blockUser(String blockedId) async {
    blocked.add(blockedId);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeBlocks.${invocation.memberName}');
}

class _Harness {
  _Harness(this.repo, this.container, this.nav, this.blocks);

  final FakeChatRepository repo;
  final ProviderContainer container;
  final FakeNavigationService nav;
  final _FakeBlocks blocks;
  late _HostState state;

  List<String> get openChats => container.read(openChatStackProvider);
}

/// Sohbet ekranlari ust uste: listedeki sira = yigin sirasi (alttan uste).
Widget _app(ProviderContainer container, List<Widget> chats) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Column(children: chats),
      ),
    );

Future<_Harness> _pump(WidgetTester tester, {List<Widget> chats = const [_HostChat()]}) async {
  final repo = FakeChatRepository();
  final nav = FakeNavigationService();
  final blocks = _FakeBlocks();
  final container = ProviderContainer(overrides: [
    chatRepositoryProvider.overrideWithValue(repo),
    navigationServiceProvider.overrideWithValue(nav),
    blockRepositoryProvider.overrideWithValue(blocks),
    matchListProvider.overrideWith(_SeededMatches.new),
  ]);
  addTearDown(container.dispose);
  await container.read(matchListProvider.future);
  final h = _Harness(repo, container, nav, blocks);
  await tester.pumpWidget(_app(container, chats));
  // Yerellestirme delegesi asenkron yuklenir (ilk kare ondan sonra); ardindan
  // initMixin microtask'i (aktif sohbet + mesaj/medya yuklemesi) ve postFrame turu.
  await tester.pump();
  await tester.pump();
  h.state = tester.state<_HostState>(find.byType(_HostChat).first);
  return h;
}

/// Sohbet ekran(lar)ini kapatir (`keep` kalanlar); ProviderScope (container)
/// yasamaya devam eder — gercekte de uygulama kapsami kalir, yalniz ekran gider.
Future<void> _closeChat(WidgetTester tester, _Harness h, {List<Widget> keep = const []}) =>
    tester.pumpWidget(_app(h.container, keep));

void main() {
  final events = <String>[];

  setUp(() {
    // Koc turu gorulmus: postFrame'deki tur denemesi overlay acmadan doner.
    SharedPreferences.setMockInitialValues({'coach_chat_question_seen': true});
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  group('acik sohbet yigini (in-app banner bastirma)', () {
    testWidgets('sohbet acilinca yigina girer, kapaninca cikar', (tester) async {
      final h = await _pump(tester);
      expect(h.openChats, ['m1']);

      await _closeChat(tester, h);

      // Eskiden dispose icindeki `ref.read` StateError atip try/catch'e
      // dusuyordu: isaret hic temizlenmiyor, o eslesmenin banner'lari sohbetten
      // cikildiktan sonra da bastiriliyordu.
      expect(h.openChats, isEmpty);
    });

    testWidgets('ayni sohbet iki kez acikken (deep link tekrarsiz push) biri kapaninca isaret kalir',
        (tester) async {
      const bottom = _HostChat(key: ValueKey('alt'));
      final h = await _pump(tester, chats: const [bottom, _HostChat(key: ValueKey('ust'))]);
      expect(h.openChats, ['m1', 'm1']);

      await _closeChat(tester, h, keep: const [bottom]);

      expect(h.openChats, ['m1']);
    });

    testWidgets('m1 -> m2 -> geri: m1 yeniden en ustte', (tester) async {
      const m1 = _HostChat(key: ValueKey('m1'));
      final h = await _pump(tester, chats: const [m1, _HostChat(key: ValueKey('m2'), matchId: 'm2')]);
      expect(h.openChats, ['m1', 'm2']);

      await _closeChat(tester, h, keep: const [m1]);

      expect(h.openChats, ['m1']);
    });
  });

  group('gonderim surerken sohbet kapanirsa', () {
    testWidgets('ilk mesaj basarili: kapali ekranda bildirim teklifi (ref) acilmaz, analitik yine atilir',
        (tester) async {
      final h = await _pump(tester);
      h.repo.sendGate = Completer<void>();
      h.state.msgCtrl.text = 'selam';

      final sending = h.state.send();
      await _closeChat(tester, h);
      h.repo.sendGate!.complete();
      await sending;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(h.repo.sentContents, ['selam']);
      expect(events, contains(AnalyticsEvents.chatMessageSend));
      expect(events, isNot(contains(AnalyticsEvents.notificationPrePromptShow)));
    });
  });

  group('acik ekranda gonderim hatasi', () {
    testWidgets('403 dogrulama kapisi: metin kutuda kalir, sayfa acilir, sayac artmaz', (tester) async {
      final h = await _pump(tester);
      h.repo.sendResult = const Failure(ServerFailure(code: 'EMAIL_VERIFICATION_REQUIRED', statusCode: 403));
      h.state.msgCtrl.text = 'selam';

      await h.state.send();

      expect(h.state.msgCtrl.text, 'selam');
      expect(h.nav.sheets, ['email_verification']);
      expect(h.state.messagesSentCount, 0);
      expect(events, isNot(contains(AnalyticsEvents.chatMessageSend)));
    });
  });

  group('medya durumu yuklenirken sohbet kapanirsa', () {
    testWidgets('foto dokunusu: await sonrasi ref kullanilmaz, sheet/istek acilmaz', (tester) async {
      final h = await _pump(tester);
      final callsBefore = h.repo.mediaStatusCalls;
      h.repo.mediaStatusGate = Completer<void>();

      final tapping = h.state.handlePhotoTap();
      await _closeChat(tester, h);
      h.repo.mediaStatusGate!.complete();
      await tapping;

      expect(tester.takeException(), isNull);
      expect(h.repo.mediaStatusCalls, callsBefore + 1);
    });

    testWidgets('ses kaydi baslatma: await sonrasi ref/setState kullanilmaz', (tester) async {
      final h = await _pump(tester);
      h.repo.mediaStatusGate = Completer<void>();

      final starting = h.state.startVoiceRecording();
      await _closeChat(tester, h);
      h.repo.mediaStatusGate!.complete();
      await starting;

      expect(tester.takeException(), isNull);
      expect(h.state.isRecording, isFalse);
    });
  });

  group('engelleme onayi beklenirken sohbet kapanirsa', () {
    testWidgets('onaylanan engel yine sunucuya gider; kapali ekranda ref/pop yok', (tester) async {
      final h = await _pump(tester);
      h.nav.dialogGate = Completer<void>();

      final blocking = h.state.onChatBlock();
      await _closeChat(tester, h);
      h.nav.dialogGate!.complete();
      await blocking;

      expect(tester.takeException(), isNull);
      expect(h.blocks.blocked, ['u-other']);
      expect(h.nav.pops, 0);
    });

    testWidgets('acik ekranda onaylanan engel sohbeti kapatir', (tester) async {
      final h = await _pump(tester);

      await h.state.onChatBlock();

      expect(h.blocks.blocked, ['u-other']);
      expect(h.nav.pops, 1);
    });
  });
}
