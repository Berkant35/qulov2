import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/notifications/mixins/notifications_screen_mixin.dart';
import 'package:qulo_v2/features/notifications/screens/notifications_screen.dart';
import 'package:qulo_v2/providers/notification_provider.dart';

import '../../../helpers/fake_navigation.dart';

/// Bildirim kutusu açılınca liste yüklenir; yükleme sürerken geri dönülürse
/// ekran kapanır ve microtask içindeki `ref` StateError atardı (yakalanmayan
/// async hata → Crashlytics). Gerçek ekran yerine aynı mixin bir host'ta kurulur.
class _HostInbox extends NotificationsScreen {
  const _HostInbox();

  @override
  ConsumerState<NotificationsScreen> createState() => _HostState();
}

class _HostState extends ConsumerState<NotificationsScreen> with NotificationsScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// Liste isteği bir kapıda bekler (ağ yok).
class _GatedNotifications extends NotificationNotifier {
  Completer<void>? fetchGate;
  int fetchCalls = 0;

  @override
  Future<void> fetchNotifications({int page = 1}) async {
    fetchCalls++;
    await fetchGate?.future;
  }
}

void main() {
  final events = <String>[];

  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  Future<(ProviderContainer, _GatedNotifications)> pump(WidgetTester tester) async {
    final notifications = _GatedNotifications()..fetchGate = Completer<void>();
    final container = ProviderContainer(overrides: [
      notificationProvider.overrideWith(() => notifications),
      navigationServiceProvider.overrideWithValue(FakeNavigationService()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: _HostInbox()),
    ));
    await tester.pump();
    return (container, notifications);
  }

  testWidgets('yükleme sürerken kutu kapanırsa: ref kullanılmaz, görüntüleme olayı atılmaz', (tester) async {
    final (container, notifications) = await pump(tester);
    expect(notifications.fetchCalls, 1);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SizedBox()),
    ));
    notifications.fetchGate!.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(events, isNot(contains(AnalyticsEvents.notificationInboxView)));
  });

  testWidgets('açık kutuda yükleme bitince görüntüleme olayı atılır', (tester) async {
    final (_, notifications) = await pump(tester);

    notifications.fetchGate!.complete();
    await tester.pump();

    expect(events, [AnalyticsEvents.notificationInboxView]);
  });
}
