import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/reward_brands.dart';

void main() {
  test('bilinen marka adı döner, OTHER ve bilinmeyen null', () {
    expect(rewardBrandName('LINEMAN'), 'LINE MAN');
    expect(rewardBrandName('TNG'), "Touch 'n Go");
    expect(rewardBrandName('OTHER'), isNull);
    expect(rewardBrandName('NEWBRAND'), isNull);
  });

  test('nasıl kullanılır anahtarı: marka küçük harf, bilinmeyen OTHER', () {
    expect(rewardHowtoKey('SHOPEEPAY'), 'reward_howto_shopeepay');
    expect(rewardHowtoKey('OTHER'), 'reward_howto_other');
    expect(rewardHowtoKey('NEWBRAND'), 'reward_howto_other');
  });

  test('her markanın (OTHER hariç) adı var', () {
    for (final key in rewardBrandKeys.where((k) => k != 'OTHER')) {
      expect(rewardBrandName(key), isNotNull, reason: key);
    }
  });
}
