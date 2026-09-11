import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/notification_manager.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/data/models/notification_model.dart';
import 'package:qulo_v2/data/repositories/chat_repository.dart';
import 'package:qulo_v2/data/repositories/notification_repository.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/chat_provider.dart';
import 'package:qulo_v2/providers/notification_provider.dart';

/// Bildirimler — push alma/dokunma, bildirim kutusu, okunmamis rozeti.
///
/// FCM (`NotificationManager`) fake: `setCallbacks`'e verilen fonksiyonlar
/// yakalanip dogrudan cagrilir. Yonlendirme karari `DeepLinkParser`'da
/// (`deep_link_parser_test`); burada yalnizca action_url'nin dogru anda
/// dogru yere iletildigi test edilir.
void main() {
  test('FCM kurulamasa da okunmamis sayisi cekilir', () async {
    final h = _Harness()..manager.failInit = true;

    await h.notifier.init();

    expect(h.state.unreadCount, 3);
  });

  group('on plan push', () {
    test('sayac artar ve banner gosterilir', () async {
      final h = await _Harness.ready();

      h.manager.onForeground!(_push(type: 'new_match', actionUrl: '/matches'));

      expect(h.state.unreadCount, 4);
      expect(h.banners, 1);
    });

    test('ayni sohbetteyken o sohbetin mesaji bastirilir — sayac yine artar', () async {
      final h = await _Harness.ready();
      h.container.read(activeChatMatchIdProvider.notifier).state = 'm1';
      final push = _push(type: 'new_message', actionUrl: '/chat/m1');

      h.manager.onForeground!(push);

      expect(h.banners, 0);
      expect(h.manager.shouldSuppress!(push), isTrue, reason: 'yerel bildirim de bastirilmali');
      expect(h.state.unreadCount, 4);
    });

    test('baska sohbetin mesaji bastirilmaz', () async {
      final h = await _Harness.ready();
      h.container.read(activeChatMatchIdProvider.notifier).state = 'm1';

      h.manager.onForeground!(_push(type: 'new_message', actionUrl: '/chat/m2'));

      expect(h.banners, 1);
    });

    test('sohbet disi bildirim aktif sohbetteyken de gosterilir', () async {
      final h = await _Harness.ready();
      h.container.read(activeChatMatchIdProvider.notifier).state = 'm1';

      h.manager.onForeground!(_push(type: 'new_match', actionUrl: '/chat/m1'));

      expect(h.banners, 1);
    });

    test('"soru cevaplandi" push\'u soru onbellegini tazeler', () async {
      final h = await _Harness.ready();

      h.manager.onForeground!(const RemoteMessage(data: {
        'type': 'chat_question_answered',
        'question_id': 'q1',
      }));
      await _settle();

      expect(h.container.read(chatQuestionCacheProvider)['q1']?.answeredOption, 'A');
    });
  });

  group('bildirime dokunma', () {
    test('kimlik ve link varsa okundu isaretlenir ve gidilir', () async {
      final h = await _Harness.ready();

      h.manager.onOpened!(_push(actionUrl: '/chat/m1', notificationId: 'n1'));
      await _settle();

      expect(h.repo.markedRead, ['n1']);
      expect(h.navigated, ['/chat/m1']);
    });

    test('UI hazir degilken (kapaliyken acilis) link kuyruga alinir, bir kez oynatilir', () async {
      final h = _Harness();
      await h.notifier.init();

      h.manager.onOpened!(_push(actionUrl: '/chat/m1'));
      expect(h.navigated, isEmpty);

      h.connectUi();
      h.connectUi();

      expect(h.navigated, ['/chat/m1']);
    });

    test('uygulamayi acan ilk bildirim ayni kuyruktan gecer', () async {
      final h = _Harness()..manager.initialMessage = _push(actionUrl: '/matches');

      await h.notifier.init();
      h.connectUi();

      expect(h.navigated, ['/matches']);
    });

    test('yerel bildirim dokunusu: UI hazir degilse kuyruga, hazir olunca gider', () async {
      final h = _Harness();
      await h.notifier.init();

      h.manager.onLocalTap!('/discover');
      h.connectUi();

      expect(h.navigated, ['/discover']);
    });
  });

  group('bildirim kutusu ve rozet', () {
    test('liste yuklenir; hata yukleniyor durumunu kapatir', () async {
      final h = await _Harness.ready();
      h.repo.list = [_item('n1'), _item('n2', isRead: true)];

      await h.notifier.fetchNotifications();
      expect(h.state.notifications.map((n) => n.id), ['n1', 'n2']);

      h.repo.listResult = const Failure(NetworkFailure());
      await h.notifier.fetchNotifications();
      expect(h.state.isLoading, isFalse);
    });

    test('okunmamis bildirim okununca isaretlenir, sayac duser', () async {
      final h = await _Harness.ready();
      h.repo.list = [_item('n1')];
      await h.notifier.fetchNotifications();

      await h.notifier.markAsRead('n1');

      expect(h.state.notifications.single.isRead, isTrue);
      expect(h.state.unreadCount, 2);
    });

    test('OKUNMUS bildirime dokunmak sayaci dusurmez', () async {
      // Kutu her dokunusta markAsRead cagiriyor; eskiden her dokunus rozeti
      // bir azaltip gercek sayinin altina indiriyordu.
      final h = await _Harness.ready();
      h.repo.list = [_item('n1', isRead: true)];
      await h.notifier.fetchNotifications();

      await h.notifier.markAsRead('n1');
      await h.notifier.markAsRead('n1');

      expect(h.state.unreadCount, 3);
    });

    test('listede olmayan bildirim (push\'tan acildi) → sayac sunucudan tazelenir', () async {
      final h = await _Harness.ready();
      h.repo.unread = 7;

      await h.notifier.markAsRead('push-only');

      expect(h.repo.markedRead, ['push-only']);
      expect(h.state.unreadCount, 7);
    });

    test('tumunu okundu yap: hepsi isaretlenir, sayac sifir', () async {
      final h = await _Harness.ready();
      h.repo.list = [_item('n1'), _item('n2')];
      await h.notifier.fetchNotifications();

      await h.notifier.markAllAsRead();

      expect(h.state.notifications.every((n) => n.isRead), isTrue);
      expect(h.state.unreadCount, 0);
    });
  });
}

RemoteMessage _push({String? type, String? actionUrl, String? notificationId}) => RemoteMessage(data: {
      if (type != null) 'type': type,
      if (actionUrl != null) 'action_url': actionUrl,
      if (notificationId != null) 'notification_id': notificationId,
    });

NotificationModel _item(String id, {bool isRead = false}) => NotificationModel(
      id: id,
      userId: 'me',
      type: 'new_match',
      title: 'Yeni eslesme',
      body: 'Ayse ile eslestin',
      actionUrl: '/matches',
      isRead: isRead,
      createdAt: '2026-09-11T10:00:00Z',
    );

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(overrides: [
      notificationManagerProvider.overrideWithValue(manager),
      notificationRepositoryProvider.overrideWithValue(repo),
      chatRepositoryProvider.overrideWithValue(_FakeChatRepository()),
    ]);
    addTearDown(container.dispose);
  }

  /// init edilmis ve UI callback'leri bagli.
  static Future<_Harness> ready() async {
    final h = _Harness();
    await h.notifier.init();
    h.connectUi();
    return h;
  }

  final manager = _FakeNotificationManager();
  final repo = _FakeNotificationRepository();
  late final ProviderContainer container;
  final navigated = <String>[];
  int banners = 0;

  NotificationNotifier get notifier => container.read(notificationProvider.notifier);
  NotificationState get state => container.read(notificationProvider);

  void connectUi() => notifier.setUICallbacks(
        onForegroundNotification: (_) => banners++,
        onNavigate: navigated.add,
      );
}

class _FakeNotificationManager implements NotificationManager {
  bool failInit = false;
  RemoteMessage? initialMessage;

  void Function(RemoteMessage)? onForeground;
  void Function(RemoteMessage)? onOpened;
  bool Function(RemoteMessage)? shouldSuppress;
  void Function(String)? onLocalTap;

  @override
  void setCallbacks({
    void Function(String token)? onTokenRefresh,
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
    bool Function(RemoteMessage message)? shouldSuppress,
    void Function(String actionUrl)? onLocalNotificationTap,
  }) {
    onForeground = onForegroundMessage;
    onOpened = onMessageOpenedApp;
    this.shouldSuppress = shouldSuppress;
    onLocalTap = onLocalNotificationTap;
  }

  @override
  Future<void> init() async {
    if (failInit) throw Exception('FCM yok');
  }

  @override
  String? get token => null;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNotificationManager.${invocation.memberName}');
}

class _FakeNotificationRepository implements NotificationRepository {
  int unread = 3;
  List<NotificationModel> list = [];
  Result<List<NotificationModel>>? listResult;
  final markedRead = <String>[];

  @override
  Future<Result<List<NotificationModel>>> getNotifications(int page, int limit) async =>
      listResult ?? Success(list);

  @override
  Future<Result<int>> getUnreadCount() async => Success(unread);

  @override
  Future<Result<void>> markAsRead(String id) async {
    markedRead.add(id);
    return const Success(null);
  }

  @override
  Future<Result<void>> markAllAsRead() async => const Success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNotificationRepository.${invocation.memberName}');
}

class _FakeChatRepository implements ChatRepository {
  @override
  Future<Result<ChatQuestionModel>> getQuestion(String questionId) async => Success(ChatQuestionModel(
        id: questionId,
        matchId: 'm1',
        senderId: 'me',
        questionText: 'En sevdigim sehir?',
        optionA: 'Izmir',
        optionB: 'Ankara',
        answeredOption: 'A',
        createdAt: '2026-09-11T10:00:00Z',
      ));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeChatRepository.${invocation.memberName}');
}
