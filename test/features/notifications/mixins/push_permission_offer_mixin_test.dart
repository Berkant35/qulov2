import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/navigation/models/app_bottom_sheet.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/notification_manager.dart';
import 'package:qulo_v2/data/repositories/user_repository.dart';
import 'package:qulo_v2/features/notifications/mixins/push_permission_offer_mixin.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Bildirim izni login sonrası soğuk istenmez; değerli anda (eşleşme, ilk
/// mesaj) önce açıklama ekranı, kabul edilirse sistem istemi.
class _Host extends ConsumerStatefulWidget {
  const _Host();

  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> with PushPermissionOfferMixin<_Host> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  final events = <String>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  Future<_Harness> pump(WidgetTester tester, {required bool canRequest, bool? accept}) async {
    final h = _Harness(_FakeNavigationService(accept), _FakeNotificationManager(canRequest));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        navigationServiceProvider.overrideWithValue(h.nav),
        notificationManagerProvider.overrideWithValue(h.manager),
        userRepositoryProvider.overrideWithValue(h.users),
      ],
      child: const MaterialApp(home: _Host()),
    ));
    h.state = tester.state<_HostState>(find.byType(_Host));
    return h;
  }

  testWidgets('sistem soramıyorsa (izin var / iOS red) açıklama gösterilmez', (tester) async {
    final h = await pump(tester, canRequest: false);

    final shown = await h.state.offerPushPermission(trigger: PushPromptTrigger.match);

    expect(shown, isFalse);
    expect(h.nav.sheets, isEmpty);
    expect(h.manager.requested, isEmpty);
  });

  testWidgets('kabul → sistem istemi tetikleyiciyle açılır, token sunucuya gider', (tester) async {
    final h = await pump(tester, canRequest: true, accept: true);

    final shown = await h.state.offerPushPermission(trigger: PushPromptTrigger.match);

    expect(shown, isTrue);
    expect(h.nav.sheets.single.name, 'push_permission_prompt');
    expect(h.manager.requested, ['match']);
    expect(h.users.pushTokens, ['fcm-token']);
    expect(events, [
      AnalyticsEvents.notificationPrePromptShow,
      AnalyticsEvents.notificationPrePromptAccept,
    ]);
  });

  testWidgets('şimdi değil → sistem istemi AÇILMAZ (iOS hakkı yanmaz)', (tester) async {
    final h = await pump(tester, canRequest: true, accept: false);

    final shown = await h.state.offerPushPermission(trigger: PushPromptTrigger.firstMessage);

    expect(shown, isTrue);
    expect(h.manager.requested, isEmpty);
    expect(events.last, AnalyticsEvents.notificationPrePromptDecline);
  });

  testWidgets('aynı oturumda ikinci an (eşleşme → ilk mesaj) tekrar sormaz', (tester) async {
    final h = await pump(tester, canRequest: true, accept: false);
    await h.state.offerPushPermission(trigger: PushPromptTrigger.match);

    final again = await h.state.offerPushPermission(trigger: PushPromptTrigger.firstMessage);

    expect(again, isFalse);
    expect(h.nav.sheets, hasLength(1));
  });
}

class _Harness {
  _Harness(this.nav, this.manager);

  final _FakeNavigationService nav;
  final _FakeNotificationManager manager;
  final users = _FakeUserRepository();
  late _HostState state;
}

class _FakeNavigationService implements NavigationService {
  _FakeNavigationService(this._accept);

  final bool? _accept;
  final sheets = <AppBottomSheet>[];

  @override
  Future<T?> showAppBottomSheet<T>(AppBottomSheet sheet) async {
    sheets.add(sheet);
    return _accept as T?;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNavigationService.${invocation.memberName}');
}

class _FakeNotificationManager implements NotificationManager {
  _FakeNotificationManager(this._canRequest);

  final bool _canRequest;
  final requested = <String>[];
  String? _token;

  @override
  Future<bool> canRequestPermission() async => _canRequest;

  @override
  Future<bool> requestPermission({required String trigger}) async {
    requested.add(trigger);
    _token = 'fcm-token';
    return true;
  }

  @override
  String? get token => _token;

  @override
  void setCallbacks({
    void Function(String token)? onTokenRefresh,
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
    bool Function(RemoteMessage message)? shouldSuppress,
    void Function(String actionUrl)? onLocalNotificationTap,
  }) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNotificationManager.${invocation.memberName}');
}

class _FakeUserRepository implements UserRepository {
  final pushTokens = <String>[];

  @override
  Future<Result<void>> updatePushToken(String token) async {
    pushTokens.add(token);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeUserRepository.${invocation.memberName}');
}
