import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/pref_consent/gender_pref_label.dart';

/// Profil ve düzenleme ekranı aynı etiketleri gösterir (eskiden Men/Women vs Male/Female);
/// tercih yokken "Herkes" DEĞİL "saklanmıyor" yazar (eski default dalı yanıltıyordu).
void main() {
  const table = {
    'MAN': 'men',
    'WOMAN': 'women',
    'BOTH': 'both',
    null: 'gender_pref_not_stored',
  };
  table.forEach((pref, key) {
    test('$pref → $key', () => expect(genderPrefLabelKey(pref), key));
  });
}
