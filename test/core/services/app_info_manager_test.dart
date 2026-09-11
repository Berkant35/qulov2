import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/app_info_manager.dart';

/// `x-app-version` basliginin bicimi — sunucu yalnizca `2.0.10` ya da `2.0.10+73`
/// kabul ediyor (qulo-server `utils/client-meta.ts`), gerisini sessizce atiyor.
void main() {
  group('AppInfoManager.headerVersionOf', () {
    test('surum + build: sunucunun bekledigi 2.0.10+73 bicimi', () {
      expect(AppInfoManager.headerVersionOf('2.0.10', '73'), '2.0.10+73');
    });

    test('build numarasi bossa yalnizca surum — "2.0.10+" sunucuda reddedilirdi', () {
      expect(AppInfoManager.headerVersionOf('2.0.10', ''), '2.0.10');
    });
  });
}
