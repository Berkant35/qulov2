import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/notifications/widgets/notification_card.dart';
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
    Future.microtask(
      () => ref.read(notificationProvider.notifier).fetchNotifications(),
    );
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
    final theme = Theme.of(context);

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
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(NotificationState state, ThemeData theme) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: AppLoadingWidget.large());
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Text(
            context.tr('no_notifications'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationProvider.notifier).fetchNotifications(),
      child: ListView.builder(
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final n = state.notifications[index];
          return NotificationCard(
            notification: n,
            onTap: () => _onTap(n.id, n.actionUrl),
            onActionTap: () => _onActionTap(n.id, n.actionUrl),
          );
        },
      ),
    );
  }
}
