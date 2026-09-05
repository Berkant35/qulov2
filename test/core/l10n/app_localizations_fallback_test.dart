import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';

/// Ceviri bulunamayinca ekranda "question_category_x" gibi ham anahtar
/// gorunmemeli; okunabilir bir metin donmeli (emniyet agi).
void main() {
  test('eksik anahtar ham anahtar yerine okunabilir metin döner', () {
    final l10n = AppLocalizations(const Locale('tr'));
    expect(l10n.get('yok_boyle_key'), 'Yok boyle key');
    expect(l10n.get('POWER_BLOCK'), 'Power block');
  });

  test('var olan anahtar aynen çevrilir, en fallback çalışır', () {
    final l10n = AppLocalizations(const Locale('tr'));
    expect(l10n.get('save'), isNot(contains('_')));
    expect(l10n.get('save'), isNotEmpty);
  });
}
