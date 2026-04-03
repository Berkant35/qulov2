import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/settings/screens/settings_screen.dart';
import 'package:qulo_v2/core/config/env.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/locale_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/providers/theme_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

mixin SettingsScreenMixin on ConsumerState<SettingsScreen> {
  void initMixin() {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.settingsScreenView);
  }

  void disposeMixin() {}

  Future<void> onLanguageTap() async {
    final locale = ref.read(localeProvider);
    final nav = ref.read(navigationServiceProvider);
    final result = await nav.showAppBottomSheet<List<String>>(
      CustomBottomSheet(
        name: 'language_picker',
        builder: (_) => LanguagePickerSheet(
          selectedLanguages: [locale.languageCode],
          multiSelect: false,
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      final oldLang = locale.languageCode;
      final newLang = result.first;
      if (oldLang != newLang) {
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.settingsLanguageChange,
          params: {AnalyticsEvents.paramLanguage: newLang},
        );
        AnalyticsManager.instance.logEvent(
          AnalyticsEvents.settingsChange,
          params: {
            AnalyticsEvents.paramSettingName: 'language',
            AnalyticsEvents.paramOldValue: oldLang,
            AnalyticsEvents.paramNewValue: newLang,
          },
        );
        ref.read(localeProvider.notifier).setLocale(Locale(newLang));
      }
    }
  }

  void onThemeChanged(Set<AppThemeMode> selection) {
    final oldTheme = ref.read(themeProvider).name;
    final newTheme = selection.first;
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.settingsChange,
      params: {
        AnalyticsEvents.paramSettingName: 'theme',
        AnalyticsEvents.paramOldValue: oldTheme,
        AnalyticsEvents.paramNewValue: newTheme.name,
      },
    );
    ref.read(themeProvider.notifier).setThemeMode(newTheme);
  }

  Future<void> onOpenTerms() async {
    ref.read(navigationServiceProvider).push(RouteNames.terms);
  }

  Future<void> onOpenPrivacy() async {
    ref.read(navigationServiceProvider).push(RouteNames.privacyPolicy);
  }

  Future<void> onBlockedUsers() async {
    ref.read(navigationServiceProvider).push(RouteNames.blockedUsers);
  }

  Future<void> onMyTickets() async {
    ref.read(navigationServiceProvider).push(RouteNames.myTickets);
  }

  Future<void> onHelp() async {
    final locale = ref.read(localeProvider).languageCode;
    ref.read(navigationServiceProvider).push(
      RouteNames.help,
      extra: '${Env.legalBaseUrl}/$locale/help/',
    );
  }

  Future<void> onLogout() async {
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
  }

  Future<void> onDeleteAccount() async {
    AnalyticsManager.instance.logEvent(AnalyticsEvents.settingsDeleteAccountStart);
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
  }
}
