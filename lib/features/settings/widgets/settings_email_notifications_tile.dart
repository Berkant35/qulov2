import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/settings/mixins/settings_email_notifications_tile_mixin.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class SettingsEmailNotificationsTile extends ConsumerWidget
    with SettingsEmailNotificationsTileMixin {
  const SettingsEmailNotificationsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final value = ref.watch(userProvider).valueOrNull?.emailNotificationsEnabled ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: SwitchListTile(
        secondary: Icon(Icons.email_outlined, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          context.tr('email_notifications'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          context.tr('email_notifications_desc'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: (v) => onEmailNotificationsChanged(context, ref, v),
      ),
    );
  }
}
