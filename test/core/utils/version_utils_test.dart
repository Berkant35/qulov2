import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/utils/version_utils.dart';

/// Zorunlu guncelleme esigi bu karsilastirmaya bagli (`app_config_provider`).
///
/// Girdi sozlesmesi `x.y.z`: sunucu backoffice'te bu bicimi zorunlu tutuyor
/// (qulo-server `admin.controller.ts` → `updateAppConfig` regex'i), istemci ise
/// `PackageInfo.version`'i (build numarasiz) veriyor.
void main() {
  group('compareVersions', () {
    test('parcalar SAYI olarak karsilastirilir — 2.0.9 < 2.0.10', () {
      // Metin karsilastirmasi "2.0.9" > "2.0.10" derdi ve 2.0.10
      // kullanicisina zorunlu guncelleme ekrani cikarirdi.
      expect(compareVersions('2.0.9', '2.0.10'), lessThan(0));
      expect(compareVersions('2.0.10', '2.0.9'), greaterThan(0));
    });

    test('ust parca alt parcalardan baskindir', () {
      expect(compareVersions('3.0.0', '2.9.9'), greaterThan(0));
      expect(compareVersions('2.1.0', '2.0.99'), greaterThan(0));
    });

    test('esit surumler 0 doner', () {
      expect(compareVersions('2.0.10', '2.0.10'), 0);
    });

    test('eksik parca 0 sayilir — 2.0 ile 2.0.0 esit', () {
      expect(compareVersions('2.0', '2.0.0'), 0);
      expect(compareVersions('2', '2.0.1'), lessThan(0));
    });

    test('build numarali girdi FormatException atar — sozlesme disi', () {
      // Cagiran (`AppConfigNotifier.checkVersion`) bunu yakalayip `none`
      // doner; yani bu bicim sessizce "guncelleme yok" demektir.
      expect(() => compareVersions('2.0.10+73', '2.0.10'), throwsFormatException);
    });
  });

  group('isVersionLessThan', () {
    test('kesin kucukluk — esit surum guncelleme istemez', () {
      expect(isVersionLessThan('2.0.10', '2.0.10'), isFalse);
      expect(isVersionLessThan('2.0.9', '2.0.10'), isTrue);
      expect(isVersionLessThan('2.0.11', '2.0.10'), isFalse);
    });
  });
}
