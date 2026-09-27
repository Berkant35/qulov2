import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/utils/referral_share.dart';

import '../../helpers/translations.dart';


void main() {
  group('buildReferralShareMessage', () {
    test('her iki yer tutucuyu da doldurur', () {
      final message = buildReferralShareMessage(
        template: 'Kod: @code, odul @reward — quloapp.com/invite/@code',
        reward: 25,
        code: 'ABC123',
      );
      expect(message, 'Kod: ABC123, odul 25 — quloapp.com/invite/ABC123');
      expect(message, isNot(contains('@code')));
      expect(message, isNot(contains('@reward')));
    });

    test('kod sablonda iki kez geciyorsa ikisi de degisir', () {
      final message = buildReferralShareMessage(
        template: '@code ... @code',
        reward: 1,
        code: 'XYZ',
      );
      expect(message, 'XYZ ... XYZ');
    });

    test('sablonda yer tutucu yoksa metin aynen kalir', () {
      expect(
        buildReferralShareMessage(template: 'duz metin', reward: 25, code: 'A'),
        'duz metin',
      );
    });
  });

  /// Davet dongusunu sessizce olduren sey burasi: kodu tasimayan bir sablon
  /// paylasilirsa arkadas "bu kodu gir" diyen bir sayfaya duser ve girecek kod
  /// olmaz.
  ///
  /// Yer tutucularin 18 dilde ayni olmasini artik `translation_parity_test`
  /// tariyor (`@` stili de dahil, 27.09.2026'da eklendi). Burada kalan iddia
  /// ona ait olmayan tek sey: sablonun davet ADRESINI tasidigi ve donusum
  /// sonrasi ortada `@` kalmadigi.
  group('referral_share_message sablonu — 18 dil', () {
    test('dil sayisi haritada tam', expectAllLocalesPresent);

    for (final entry in allTranslations.entries) {
      test('${entry.key}: davet adresi kodla birlikte kuruluyor', () {
        final template = entry.value['referral_share_message']!;
        expect(template, contains('quloapp.com/invite/@code'));

        final message = buildReferralShareMessage(
          template: template,
          reward: 25,
          code: 'TESTCODE',
        );
        expect(message, contains('quloapp.com/invite/TESTCODE'));
        expect(message, isNot(contains('@')));
      });
    }
  });
}
