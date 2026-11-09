import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/notifications/screens/notifications_screen.dart';
import 'package:qulo_v2/providers/notification_provider.dart';

/// [NotificationsScreen] logic'i: kutu yükleme + görüntüleme ölçümü, bildirime dokunma.
mixin NotificationsScreenMixin on ConsumerState<NotificationsScreen> {
  void initMixin() => Future.microtask(loadInbox);

  /// Kutuyu tazeler; `notification_inbox_view` yükleme bitince okunmamış sayıyla atılır.
  /// Yükleme sürerken geri dönülürse ekran kapanmıştır: `ref` artık kullanılamaz
  /// ("Cannot use ref after the widget was disposed") — olay atılmaz.
  Future<void> loadInbox() async {
    if (!mounted) return;
    await ref.read(notificationProvider.notifier).fetchNotifications();
    if (!mounted) return;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.notificationInboxView,
      params: {
        AnalyticsEvents.paramUnreadCount: ref.read(notificationProvider).unreadCount,
      },
    );
  }

  Future<void> refreshInbox() => ref.read(notificationProvider.notifier).fetchNotifications();

  void markAllRead() => ref.read(notificationProvider.notifier).markAllAsRead();

  void onNotificationTap(String id, String? actionUrl) {
    ref.read(notificationProvider.notifier).markAsRead(id);
    _openActionUrl(actionUrl);
  }

  void onNotificationActionTap(String id, String? actionUrl) {
    ref.read(notificationProvider.notifier).trackClick(id);
    _openActionUrl(actionUrl);
  }

  void _openActionUrl(String? actionUrl) {
    if (actionUrl == null || actionUrl.isEmpty) return;
    ref.read(navigationServiceProvider).handleDeepLink(actionUrl);
  }
}
