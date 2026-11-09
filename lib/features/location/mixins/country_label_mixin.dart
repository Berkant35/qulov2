import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// Ülke kodu → kullanıcının dilinde ad + bayrak. Sunucu yalnız kod gönderir
/// (`GET /app/cities` → `countries`); adı mobil gösterir.
mixin CountryLabelMixin {
  /// Çevirisi olan ülkeler (sunucunun 2026-11-09 listesi). Yeni ülke gelirse
  /// ad yerine kod görünür; çeviri eklenince ad görünür.
  static const translatedCountries = {
    'TR', 'IT', 'DO', 'SA', 'IQ', 'VN', 'US', 'MX', 'SE', 'BR', 'JP', 'CN', 'SY', 'JO', 'FR', //
  };

  String countryLabel(BuildContext context, String code) {
    final upper = code.toUpperCase();
    final name = translatedCountries.contains(upper) ? context.tr('country_name_${upper.toLowerCase()}') : upper;
    final flag = countryFlag(upper);
    return flag.isEmpty ? name : '$flag $name';
  }

  /// ISO 3166-1 alpha-2 → bölgesel gösterge harfleriyle bayrak emojisi.
  static String countryFlag(String code) {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) return '';
    const regionalA = 0x1F1E6;
    const letterA = 0x41;
    return String.fromCharCodes(code.codeUnits.map((c) => regionalA + c - letterA));
  }
}
