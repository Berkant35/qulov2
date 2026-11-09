import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/notifications/mixins/notifications_screen_mixin.dart';
import 'package:qulo_v2/features/notifications/widgets/notification_list_body.dart';
import 'package:qulo_v2/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with NotificationsScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
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
            onPressed: markAllRead,
            child: Text(context.tr('mark_all_read')),
          ),
      ],
      body: NotificationListBody(
        isLoading: state.isLoading,
        notifications: state.notifications,
        onRefresh: refreshInbox,
        onTap: onNotificationTap,
        onActionTap: onNotificationActionTap,
      ),
    );
  }
}
