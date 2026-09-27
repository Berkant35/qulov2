import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/translations/ar.dart';
import 'package:qulo_v2/core/l10n/translations/de.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/core/l10n/translations/es.dart';
import 'package:qulo_v2/core/l10n/translations/fr.dart';
import 'package:qulo_v2/core/l10n/translations/hi.dart';
import 'package:qulo_v2/core/l10n/translations/id.dart';
import 'package:qulo_v2/core/l10n/translations/it.dart';
import 'package:qulo_v2/core/l10n/translations/ja.dart';
import 'package:qulo_v2/core/l10n/translations/ko.dart';
import 'package:qulo_v2/core/l10n/translations/nl.dart';
import 'package:qulo_v2/core/l10n/translations/pl.dart';
import 'package:qulo_v2/core/l10n/translations/pt.dart';
import 'package:qulo_v2/core/l10n/translations/ru.dart';
import 'package:qulo_v2/core/l10n/translations/sv.dart';
import 'package:qulo_v2/core/l10n/translations/th.dart';
import 'package:qulo_v2/core/l10n/translations/tr.dart';
import 'package:qulo_v2/core/l10n/translations/zh.dart';

/// Uygulamanin 18 dil haritasi, testler icin tek yerde.
///
/// `AppLocalizations._localizedValues` private oldugu icin ayni liste burada
/// tutulmak zorunda. Iki test dosyasi (parity ve davet paylasim metni) ayni
/// listeyi ayri ayri tuttugunda 19. dil eklenince biri sessizce o dili
/// atliyordu — o yuzden tek kopya.
const allTranslations = <String, Map<String, String>>{
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
  'th': thTranslations,
  'id': idTranslations,
};

/// Yeni dil eklenip bu haritaya yazilmazsa her iki test de o dili atlar; bu
/// yuzden sayiyi burada sabitliyoruz.
void expectAllLocalesPresent() {
  expect(allTranslations.length, 18);
}
