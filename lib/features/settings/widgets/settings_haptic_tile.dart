import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/haptic_provider.dart';

class SettingsHapticTile extends ConsumerWidget {
  const SettingsHapticTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: SwitchListTile(
        secondary: Icon(Icons.vibration, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          context.tr('haptic_feedback'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          context.tr('haptic_feedback_desc'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: ref.watch(hapticProvider),
        onChanged: (_) => ref.read(hapticProvider.notifier).toggle(),
      ),
    );
  }
}
