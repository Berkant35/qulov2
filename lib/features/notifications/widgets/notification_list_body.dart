import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/notification_model.dart';
import 'package:qulo_v2/features/notifications/widgets/notification_card.dart';

class NotificationListBody extends StatelessWidget {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final Future<void> Function() onRefresh;
  final void Function(String id, String? actionUrl) onTap;
  final void Function(String id, String? actionUrl) onActionTap;

  const NotificationListBody({
    super.key,
    required this.isLoading,
    required this.notifications,
    required this.onRefresh,
    required this.onTap,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && notifications.isEmpty) {
      return const Center(child: AppLoadingWidget.large());
    }

    if (notifications.isEmpty) {
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
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return NotificationCard(
            notification: n,
            onTap: () => onTap(n.id, n.actionUrl),
            onActionTap: () => onActionTap(n.id, n.actionUrl),
          );
        },
      ),
    );
  }
}
