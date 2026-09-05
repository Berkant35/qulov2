import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/features/settings/screens/create_ticket_screen.dart';

/// `context.tr('prefix_$deger')` ile kurulan dinamik anahtarlar: her deger
/// kumesinin tum elemanlari en.dart'ta olmali (parite testi 16 dile yayar).
void main() {
  void expectKeys(String family, Iterable<String> keys) {
    final missing = keys.where((k) => !enTranslations.containsKey(k)).toList();
    expect(missing, isEmpty, reason: '$family eksik anahtarlar: $missing');
  }

  test('locale_<dil> — 16 soru dili', () {
    expectKeys('locale', AppConstants.supportedQuestionLocales.map((l) => 'locale_$l'));
  });

  test('question_category_<kategori>', () {
    expectKeys('question_category', AppConstants.questionCategories.map((c) => 'question_category_$c'));
  });

  test('zodiac_<burç>', () {
    expectKeys('zodiac', AppConstants.zodiacSigns.map((s) => 'zodiac_$s'));
  });

  test('ticket_cat_<kategori>', () {
    expectKeys('ticket_cat', ticketCategories.map((c) => 'ticket_cat_${c.toLowerCase()}'));
  });

  test('quiz_result_<rozet> — sunucu quiz.service performanceBadge değerleri', () {
    const badges = ['flawless', 'speed_solver', 'power_master', 'determined'];
    expectKeys('quiz_result', badges.map((b) => 'quiz_result_$b'));
  });

  test('analytics_difficulty_<zorluk> — sunucu zorluk değerleri', () {
    const levels = ['easy', 'medium', 'hard', 'legendary', 'unranked'];
    expectKeys('analytics_difficulty', levels.map((d) => 'analytics_difficulty_$d'));
  });

  test('güç adı → etiket ve açıklama anahtarları (8 güç)', () {
    expectKeys('power label', powerNames.map(powerLabelKey));
    expectKeys('power desc', powerNames.map(powerDescKey));
  });
}
