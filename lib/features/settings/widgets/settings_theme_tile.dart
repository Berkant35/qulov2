import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/theme_provider.dart';

class SettingsThemeTile extends ConsumerWidget {
  final ValueChanged<Set<AppThemeMode>> onChanged;

  const SettingsThemeTile({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.brightness_6, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.lg),
              Text(context.tr('theme'), style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              segments: [
                ButtonSegment(value: AppThemeMode.system, label: Text(context.tr('theme_system'))),
                ButtonSegment(value: AppThemeMode.light, label: Text(context.tr('theme_light'))),
                ButtonSegment(value: AppThemeMode.dark, label: Text(context.tr('theme_dark'))),
              ],
              selected: {ref.watch(themeProvider)},
              onSelectionChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
