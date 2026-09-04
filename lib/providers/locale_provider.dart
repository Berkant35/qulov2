import 'dart:async';
import 'package:flutter/widgets.dart';
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

  /// Bolge her zaman cihazdan: dil tercihi kullanicinin, ulke kodu cihazin.
  /// `en_US` ile `en_GB` boylece ayrilir (12/24 saat, mil/km buradan turer).
  /// `WidgetsBinding.instance.platformDispatcher` uzerinden okunur (dart:ui'nin
  /// ham singleton'u degil): testte `tester.platformDispatcher.localesTestValue`
  /// ile override edilebilsin diye — ikisi ayni nesne, canlida da tek gercek kaynak.
  static String? get _deviceCountry =>
      WidgetsBinding.instance.platformDispatcher.locales.firstOrNull?.countryCode;

  static Locale _withRegion(String languageCode) => Locale(languageCode, _deviceCountry);

  /// Cihazın tercih ettiği diller sırasıyla taranır; ilk desteklenen dil seçilir.
  /// Hiçbiri desteklenmiyorsa [_fallback] (İngilizce) döner.
  static Locale _deviceLocaleOrFallback() {
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      if (AppLocalizationsDelegate.supportedCodes.contains(locale.languageCode)) {
        return _withRegion(locale.languageCode);
      }
    }
    return _withRegion(_fallback.languageCode);
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = _withRegion(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = _withRegion(locale.languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);

    // Authenticated user: backend'e sync (best-effort, fire-and-forget) — yalniz dil kodu
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      unawaited(
        ref.read(userRepositoryProvider).updateProfile({'locale': locale.languageCode}),
      );
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
