import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/translations/tr.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/core/l10n/translations/de.dart';
import 'package:qulo_v2/core/l10n/translations/fr.dart';
import 'package:qulo_v2/core/l10n/translations/es.dart';
import 'package:qulo_v2/core/l10n/translations/ar.dart';
import 'package:qulo_v2/core/l10n/translations/ru.dart';
import 'package:qulo_v2/core/l10n/translations/pt.dart';
import 'package:qulo_v2/core/l10n/translations/it.dart';
import 'package:qulo_v2/core/l10n/translations/ja.dart';
import 'package:qulo_v2/core/l10n/translations/ko.dart';
import 'package:qulo_v2/core/l10n/translations/zh.dart';
import 'package:qulo_v2/core/l10n/translations/nl.dart';
import 'package:qulo_v2/core/l10n/translations/pl.dart';
import 'package:qulo_v2/core/l10n/translations/sv.dart';
import 'package:qulo_v2/core/l10n/translations/hi.dart';

class AppLocalizations {
  final Locale locale;
  late final Map<String, String> _strings;

  AppLocalizations(this.locale) {
    _strings = _localizedValues[locale.languageCode]
        ?? _localizedValues['en']!; // Fallback to English for untranslated languages
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get(String key) => _strings[key] ?? key;

  String errorMessage(String code) {
    final key = 'error_${code.toLowerCase()}';
    return _strings[key] ?? _strings['error_unknown']!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'tr': trTranslations,
    'en': enTranslations,
    'de': deTranslations,
    'fr': frTranslations,
    'es': esTranslations,
    'ar': arTranslations,
    'ru': ruTranslations,
    'pt': ptTranslations,
    'it': itTranslations,
    'ja': jaTranslations,
    'ko': koTranslations,
    'zh': zhTranslations,
    'nl': nlTranslations,
    'pl': plTranslations,
    'sv': svTranslations,
    'hi': hiTranslations,
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  /// All 16 supported locales — falls back to TR if translations not yet available
  static const _supportedCodes = {
    'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru', 'pt',
    'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv', 'hi',
  };

  @override
  bool isSupported(Locale locale) =>
      _supportedCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
