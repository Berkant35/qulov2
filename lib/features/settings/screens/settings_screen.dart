import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/locale_provider.dart';
import 'package:qulo_v2/providers/theme_provider.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/user_languages_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final languagesAsync = ref.watch(userLanguagesProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('settings'),
      padding: EdgeInsets.zero,
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ListTile(
              leading: Icon(Icons.language, color: theme.colorScheme.onSurfaceVariant),
              title: Text(
                context.tr('language'),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'tr', label: Text('TR')),
                  ButtonSegment(value: 'en', label: Text('EN')),
                ],
                selected: {locale.languageCode},
                onSelectionChanged: (s) {
                  ref.read(localeProvider.notifier).setLocale(Locale(s.first));
                },
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ListTile(
              leading: Icon(Icons.translate, color: theme.colorScheme.onSurfaceVariant),
              title: Text(
                context.tr('settings_question_languages'),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              subtitle: languagesAsync.when(
                data: (langs) => langs.isEmpty
                    ? Text(context.tr('settings_question_languages_none'))
                    : Text(
                        langs
                            .map((l) =>
                                '${AppConstants.localeFlagEmojis[l] ?? ''} ${context.tr('locale_$l')}')
                            .join(', '),
                      ),
                loading: () => const AppLoadingWidget.small(),
                error: (_, __) => Text(context.tr('error')),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final currentLangs = languagesAsync.valueOrNull ?? [];
                final result = await showModalBottomSheet<List<String>>(
                  context: context,
                  builder: (_) => LanguagePickerSheet(
                    selectedLanguages: currentLangs,
                    multiSelect: true,
                  ),
                );
                if (result != null) {
                  ref.read(userLanguagesProvider.notifier).save(result);
                }
              },
            ),
          ),
          Container(
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
                    onSelectionChanged: (s) {
                      ref.read(themeProvider.notifier).setThemeMode(s.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.onSurfaceVariant),
              title: Text(
                context.tr('logout'),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () async {
                final nav = ref.read(navigationServiceProvider);
                final authNotifier = ref.read(authProvider.notifier);
                final confirm = await nav.showAppDialog<bool>(
                  ConfirmDialog(
                    name: 'logout',
                    title: context.tr('logout'),
                    message: context.tr('logout_confirm'),
                    confirmText: context.tr('logout'),
                  ),
                );
                if (confirm == true) {
                  await authNotifier.logout();
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text(
                context.tr('delete_account'),
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                final nav = ref.read(navigationServiceProvider);
                final userNotifier = ref.read(userProvider.notifier);
                final authNotifier = ref.read(authProvider.notifier);
                final confirm = await nav.showAppDialog<bool>(
                  ConfirmDialog(
                    name: 'delete_account',
                    title: context.tr('delete_account'),
                    message: context.tr('delete_account_desc'),
                    confirmText: context.tr('delete'),
                    isDestructive: true,
                  ),
                );
                if (confirm == true) {
                  await userNotifier.deleteAccount();
                  await authNotifier.logout();
                }
              },
            ),
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
