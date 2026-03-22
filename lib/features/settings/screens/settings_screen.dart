import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/settings/mixins/settings_screen_mixin.dart';
import 'package:qulo_v2/features/settings/widgets/settings_action_tile.dart';
import 'package:qulo_v2/features/settings/widgets/settings_language_tile.dart';
import 'package:qulo_v2/features/settings/widgets/settings_theme_tile.dart';
import 'package:qulo_v2/providers/haptic_provider.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SettingsScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('settings'),
      padding: EdgeInsets.zero,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          SettingsLanguageTile(onTap: onLanguageTap),
          SettingsThemeTile(onChanged: onThemeChanged),
          _HapticTile(),
          const SizedBox(height: AppSpacing.sm),
          SettingsActionTile(
            icon: Icons.logout,
            title: context.tr('logout'),
            onTap: onLogout,
          ),
          SettingsActionTile(
            icon: Icons.delete_forever,
            iconColor: context.appColors.error,
            title: context.tr('delete_account'),
            titleColor: context.appColors.error,
            onTap: onDeleteAccount,
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: ref.watch(_packageInfoProvider).when(
              data: (info) => Text(
                'v${info.version} (${info.buildNumber})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _HapticTile extends ConsumerWidget {
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
