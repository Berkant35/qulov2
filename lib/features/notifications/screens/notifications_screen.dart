import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/notifications/widgets/notification_list_body.dart';
import 'package:qulo_v2/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(notificationProvider.notifier).fetchNotifications();
      final unreadCount = ref.read(notificationProvider).unreadCount;
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.notificationInboxView,
        params: {
          AnalyticsEvents.paramUnreadCount: unreadCount,
        },
      );
    });
  }

  void _onTap(String id, String? actionUrl) {
    ref.read(notificationProvider.notifier).markAsRead(id);
    if (actionUrl != null && actionUrl.isNotEmpty) {
      ref.read(navigationServiceProvider).handleDeepLink(actionUrl);
    }
  }

  void _onActionTap(String id, String? actionUrl) {
    ref.read(notificationProvider.notifier).trackClick(id);
    if (actionUrl != null && actionUrl.isNotEmpty) {
      ref.read(navigationServiceProvider).handleDeepLink(actionUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return AppScaffold(
      title: context.tr('notifications'),
      showBackButton: true,
      padding: EdgeInsets.zero,
      actions: [
        if (state.unreadCount > 0)
          TextButton(
            onPressed: () =>
                ref.read(notificationProvider.notifier).markAllAsRead(),
            child: Text(context.tr('mark_all_read')),
          ),
      ],
      body: NotificationListBody(
        isLoading: state.isLoading,
        notifications: state.notifications,
        onRefresh: () =>
            ref.read(notificationProvider.notifier).fetchNotifications(),
        onTap: _onTap,
        onActionTap: _onActionTap,
      ),
    );
  }
}
