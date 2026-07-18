import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'app_locale';

  /// İlk kurulumda kayıtlı seçim yokken kullanılacak fallback dili.
  /// Cihaz dili desteklenmiyorsa buna düşülür (TR'ye değil — yurt dışı bug'ı).
  static const _fallback = Locale('en');

  @override
  Locale build() {
    _loadSaved();
    return _deviceLocaleOrFallback();
  }

  /// Cihazın tercih ettiği diller sırasıyla taranır; ilk desteklenen dil seçilir.
  /// Hiçbiri desteklenmiyorsa [_fallback] (İngilizce) döner.
  static Locale _deviceLocaleOrFallback() {
    for (final locale in PlatformDispatcher.instance.locales) {
      if (AppLocalizationsDelegate.supportedCodes.contains(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return _fallback;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);

    // Authenticated user: backend'e sync (best-effort, fire-and-forget)
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      unawaited(
        ref.read(userRepositoryProvider).updateProfile({'locale': locale.languageCode}),
      );
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
