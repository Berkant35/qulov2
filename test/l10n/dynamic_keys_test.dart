import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/diamond_reason_labels.dart';
import 'package:qulo_v2/core/constants/power_labels.dart';
import 'package:qulo_v2/core/constants/reward_brands.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/rewards_market/domain/redeem_error.dart';

/// `context.tr('prefix_$deger')` ile kurulan dinamik anahtarlar: her deger
/// kumesinin tum elemanlari en.dart'ta olmali (parite testi 18 dile yayar).
void main() {
  void expectKeys(String family, Iterable<String> keys) {
    final missing = keys.where((k) => !enTranslations.containsKey(k)).toList();
    expect(missing, isEmpty, reason: '$family eksik anahtarlar: $missing');
  }

  test('locale_<dil> — 18 soru dili', () {
    expectKeys('locale', AppConstants.supportedQuestionLocales.map((l) => 'locale_$l'));
  });

  test('question_category_<kategori>', () {
    expectKeys('question_category', AppConstants.questionCategories.map((c) => 'question_category_$c'));
  });

  test('zodiac_<burç>', () {
    expectKeys('zodiac', AppConstants.zodiacSigns.map((s) => 'zodiac_$s'));
  });

  test('ticket_cat_<kategori>', () {
    expectKeys('ticket_cat', AppConstants.ticketCategories.map((c) => 'ticket_cat_${c.toLowerCase()}'));
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

  test('sonuç kartı satır etiketi: ANSWER doğru cevap, güçler güç etiketi', () {
    expect(powerUsageLabelKey('ANSWER'), 'result_correct_answer');
    expect(powerUsageLabelKey('HALF'), 'power_half');
    expect(powerUsageLabelKey('TIME_EXTEND'), 'power_time');
    expectKeys('power usage label', ['ANSWER', ...powerNames].map(powerUsageLabelKey));
  });

  test('elmas işlem sebebi ve türü anahtarları', () {
    expectKeys('diamond reason', diamondReasonKeys);
    expectKeys('diamond type', ['GREEN', 'PURPLE', 'RAINBOW'].map(diamondTypeKey));
  });

  test('Rainbow ekran anahtarları (Plan 3)', () {
    expectKeys('rainbow', ['result_rainbow_earned', 'result_rainbow_subtitle', 'rainbow_not_available']);
  });

  test('Rainbow Market marka anahtarları (Plan 5)', () {
    expectKeys('reward howto', rewardBrandKeys.map(rewardHowtoKey));
    expectKeys('reward brand', ['reward_brand_other']);
  });

  test('talep durumu anahtarları (Plan 5)', () {
    expectKeys('redemption status', RedemptionStatus.values.map(redemptionStatusKey));
  });

  test('itfa hatası anahtarları (Plan 5)', () {
    expectKeys('redeem error', RedeemErrorKind.values.map(redeemErrorKey));
  });
}
