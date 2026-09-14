import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';

/// Eşleşme dil tercihinin varsayılanı = uygulama dili. Uygulama dili
/// desteklenmiyorsa (bugün Tay/Endonez cihaz) `en`'e düşer — `tr`'ye DEĞİL.
/// 2026-09-13: onboarding iki yerde `'tr'`'ye düşüyordu; yabancı cihaz Türkçe
/// tercihle kaydolup yalnız Türkçe sorulu profilleri görüyordu.
void main() {
  group('AppConstants.defaultQuestionLocale', () {
    test('desteklenen uygulama dili olduğu gibi döner', () {
      expect(AppConstants.defaultQuestionLocale('fr'), 'fr');
      expect(AppConstants.defaultQuestionLocale('tr'), 'tr');
    });

    test('desteklenmeyen dil en\'e düşer, tr\'ye değil', () {
      // 'th' artık destekleniyor (2026-09-14); desteklenmeyen örnek Vietnamca.
      expect(AppConstants.defaultQuestionLocale('vi'), 'en');
      expect(AppConstants.defaultQuestionLocale(''), 'en');
    });

    test('bölge/betik ekli kod dile indirgenir: tr_TR → tr, pt-BR → pt', () {
      // Sosyal giriş gövdesinde `tr_TR` biçimi dolaşıyor; sunucu localeFromTag ile aynı.
      expect(AppConstants.defaultQuestionLocale('tr_TR'), 'tr');
      expect(AppConstants.defaultQuestionLocale('pt-BR'), 'pt');
      expect(AppConstants.defaultQuestionLocale('zh_Hans_CN'), 'zh');
      expect(AppConstants.defaultQuestionLocale('xx_YY'), AppConstants.fallbackLocale);
    });

    test('her desteklenen dil kendine döner — liste ile kural ayrışmaz', () {
      for (final code in AppConstants.supportedQuestionLocales) {
        expect(AppConstants.defaultQuestionLocale(code), code);
      }
    });
  });
}
