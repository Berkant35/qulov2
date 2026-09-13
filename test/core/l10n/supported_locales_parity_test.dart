import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';

/// Uygulama dili listesi ile soru/eşleşme dili listesi aynı 16 kod olmalı.
/// `LanguagePickerSheet` uygulama dili seçici olarak `supportedQuestionLocales`'i
/// dolaşır; listeler ayrışırsa kullanıcı delegate'in desteklemediği bir dili seçer
/// ve `AppLocalizations.of(context)!` null-check ile çöker (th/id eklerken tuzak).
void main() {
  test('delegate.supportedCodes == AppConstants.supportedQuestionLocales', () {
    expect(
      AppLocalizationsDelegate.supportedCodes,
      AppConstants.supportedQuestionLocales.toSet(),
    );
  });

  test('her desteklenen kodun kendi çeviri haritası yüklü (İngilizce\'ye düşmüyor)', () {
    // `locale_*` anahtarları her dilde aynı (native ad) olduğu için ayırt etmez;
    // 'cancel' her dilde farklı çevrilir.
    final en = AppLocalizations(const Locale('en')).get('cancel');
    for (final code in AppConstants.supportedQuestionLocales.where((c) => c != 'en')) {
      final own = AppLocalizations(Locale(code)).get('cancel');
      expect(own, isNot(en), reason: '$code haritası yok, en\'e düştü');
    }
  });

  test('uygulama dili fallback\'i tek sabit: en', () {
    expect(AppConstants.fallbackLocale, 'en');
    expect(AppLocalizationsDelegate.supportedCodes, contains(AppConstants.fallbackLocale));
  });
}
