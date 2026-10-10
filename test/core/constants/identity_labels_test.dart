import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';

/// Spec 2026-10-06 §1 kanonik liste (sıra dahil) — sunucu kataloğuyla aynı.
void main() {
  test('kimlik', () {
    expect(IdentityLabels.gender, [
      'cis_woman', 'cis_man', 'trans_woman', 'trans_man', 'non_binary', 'genderqueer', 'genderfluid',
      'agender', 'bigender', 'intersex', 'transfeminine', 'transmasculine', 'questioning',
    ]);
  });
  test('yönelim', () {
    expect(IdentityLabels.orientation, [
      'straight', 'gay', 'lesbian', 'bisexual', 'pansexual', 'asexual', 'demisexual', 'queer',
      'questioning', 'heteroflexible', 'homoflexible',
    ]);
  });
  test('çeviri anahtarları gruba göre önekli; sınır ve sürüm', () {
    expect(IdentityLabels.genderKey('questioning'), 'identity_gender_questioning');
    expect(IdentityLabels.orientationKey('questioning'), 'identity_orientation_questioning');
    expect(IdentityLabels.maxPerGroup, 3);
    expect(IdentityConsent.version, '2026-10-v1');
  });
  test('her etiketin önekli çeviri anahtarı en.dart\'ta var (parite testi 18 dile yayar)', () {
    final keys = [
      ...IdentityLabels.gender.map(IdentityLabels.genderKey),
      ...IdentityLabels.orientation.map(IdentityLabels.orientationKey),
    ];
    final missing = keys.where((k) => !enTranslations.containsKey(k)).toList();

    expect(keys, hasLength(24));
    expect(missing, isEmpty, reason: '$missing');
  });
}
