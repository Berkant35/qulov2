import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:qulo_v2/core/config/admob_config.dart';

void main() {
  String resolve({required bool ios, bool debug = false, String iosId = '', String androidId = ''}) =>
      AdMobConfig.resolveNativeUnitId(isDebug: debug, isIos: ios, iosOverride: iosId, androidOverride: androidId);

  test('release + override yok → Qulo gerçek birimleri (platform başına)', () {
    expect(resolve(ios: true), 'ca-app-pub-1650543626009624/8012023743');
    expect(resolve(ios: false), 'ca-app-pub-1650543626009624/3414303180');
  });

  test('debug + override yok → Google test birimleri (gerçek reklama tıklama riski yok)', () {
    expect(resolve(ios: true, debug: true), 'ca-app-pub-3940256099942544/3986624511');
    expect(resolve(ios: false, debug: true), 'ca-app-pub-3940256099942544/2247696110');
  });

  test('dart-define her modda önceliklidir; her platform kendi kimliğini alır', () {
    for (final debug in [true, false]) {
      expect(resolve(ios: true, debug: debug, iosId: 'ca-app-pub-1/ios', androidId: 'ca-app-pub-1/and'), 'ca-app-pub-1/ios');
      expect(resolve(ios: false, debug: debug, iosId: 'ca-app-pub-1/ios', androidId: 'ca-app-pub-1/and'), 'ca-app-pub-1/and');
    }
  });

  test('dart-define yalnız diğer platform için verilmişse bu platform varsayılanı kullanır', () {
    expect(resolve(ios: true, androidId: 'ca-app-pub-1/and'), 'ca-app-pub-1650543626009624/8012023743');
  });

  test('canRequestAds: test ortamında çözümlenen birim dolu → fail-closed tetiklenmez', () {
    expect(AdMobConfig.canRequestAds, isTrue);
  });
  _requestConfigurationTests();
}

void _requestConfigurationTests() {
  group('parseTestDeviceIds', () {
    test('tanımsız/boş → boş liste', () {
      expect(AdMobConfig.parseTestDeviceIds(''), isEmpty);
      expect(AdMobConfig.parseTestDeviceIds(' , ,'), isEmpty);
    });

    test('virgülle ayırır, kırpar, boşları ve tekrarı atar', () {
      expect(AdMobConfig.parseTestDeviceIds(' A1 ,B2,,A1,C3 '), ['A1', 'B2', 'C3']);
    });
  });

  group('buildRequestConfiguration', () {
    test('yetişkin reklam kapalı (PG), çocuk/yaş altı etiketi hayır', () {
      final c = AdMobConfig.buildRequestConfiguration('');
      expect(c.maxAdContentRating, MaxAdContentRating.pg);
      expect(c.tagForChildDirectedTreatment, TagForChildDirectedTreatment.no);
      expect(c.tagForUnderAgeOfConsent, TagForUnderAgeOfConsent.no);
      expect(c.testDeviceIds, isEmpty);
    });

    test('test cihazları yapılandırmaya taşınır', () {
      expect(AdMobConfig.buildRequestConfiguration('X,Y').testDeviceIds, ['X', 'Y']);
    });
  });
}
