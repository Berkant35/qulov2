import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
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

  String get(String key) =>
      _strings[key] ?? _localizedValues['en']?[key] ?? _missing(key);

  /// Emniyet agi: anahtar hicbir dilde yoksa ham anahtar (alt cizgili) yerine
  /// okunabilir metin doner; debug'da eksik anahtari loglar.
  static String _missing(String key) {
    assert(() {
      debugPrint('[l10n] eksik ceviri anahtari: $key');
      return true;
    }());
    final words = key.replaceAll('_', ' ').trim().toLowerCase();
    if (words.isEmpty) return key;
    return words[0].toUpperCase() + words.substring(1);
  }

  /// Cogul: intl'in CLDR kurali kategoriyi secer (one/few/many/other), anahtar
  /// `key_<kategori>`; yoksa `key_other`. `{count}` yerellestirilmis sayiyla dolar.
  /// Tum dillerde `_one` ve `_other` tanimli (parite testi); ru/pl/ar'in few/many
  /// kategorileri `_other`'a duser.
  String plural(String key, int count) {
    final category = Intl.pluralLogic<String>(
      count,
      locale: locale.toString(),
      zero: 'zero', one: 'one', two: 'two', few: 'few', many: 'many', other: 'other',
    );
    final text = _strings['${key}_$category'] ??
        _strings['${key}_other'] ??
        _localizedValues['en']?['${key}_other'] ??
        _missing(key);
    // Bilincli tercih: FormatManager.instance.integer() yerine burada dogrudan
    // NumberFormat kullanilir — AppLocalizations -> FormatManager dongusunden
    // kacinir ve plural()'i singleton'a bagimli olmadan test edilebilir tutar.
    return text.replaceAll(
      '{count}',
      NumberFormat.decimalPattern(locale.toString()).format(count),
    );
  }

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
  static const supportedCodes = {
    'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru', 'pt',
    'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv', 'hi',
  };

  @override
  bool isSupported(Locale locale) =>
      supportedCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
