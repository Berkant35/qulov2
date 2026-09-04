import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';

/// Çoğul: CLDR kategorisi (one/few/many/other) → `key_<kategori>`, yoksa `key_other`.
void main() {
  test('İngilizce tekil/çoğul ayrımı', () {
    final l10n = AppLocalizations(const Locale('en'));
    expect(l10n.plural('time_minutes_ago', 1), '1 minute ago');
    expect(l10n.plural('time_minutes_ago', 5), '5 minutes ago');
  });

  test('Türkçe tek biçim (other)', () {
    final l10n = AppLocalizations(const Locale('tr'));
    expect(l10n.plural('time_minutes_ago', 1), '1 dakika önce');
    expect(l10n.plural('time_minutes_ago', 5), '5 dakika önce');
  });

  test('Rusça few kategorisi anahtarı yoksa other\'a düşer', () {
    final l10n = AppLocalizations(const Locale('ru'));
    // 3 → CLDR "few"; ru dosyasında yalnız _one/_other var.
    expect(l10n.plural('time_days_ago', 3), '3 дней назад');
    expect(l10n.plural('time_days_ago', 1), '1 день назад');
  });

  test('{count} yerelleştirilmiş sayı ile dolar', () {
    final l10n = AppLocalizations(const Locale('de'));
    expect(l10n.plural('time_minutes_ago', 1000), 'vor 1.000 Minuten');
  });

  test('bilinmeyen anahtar anahtarın kendisini döner (crash yok)', () {
    final l10n = AppLocalizations(const Locale('en'));
    expect(l10n.plural('yok_boyle_key', 2), 'yok_boyle_key');
  });
}
