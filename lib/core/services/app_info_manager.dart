import 'package:package_info_plus/package_info_plus.dart';

/// Uygulama paket bilgisi (surum, build numarasi) icin tek erisim noktasi.
///
/// `package_info_plus` dogrudan ekran/mixin icinde kullanilmaz — Hardware/Device
/// Package Rule geregi bu manager uzerinden `appInfoManagerProvider` ile erisilir.
class AppInfoManager {
  AppInfoManager._();
  static final AppInfoManager instance = AppInfoManager._();

  PackageInfo? _cached;

  Future<PackageInfo> get packageInfo async =>
      _cached ??= await PackageInfo.fromPlatform();

  Future<String> get version async => (await packageInfo).version;

  /// Ayarlar ekraninda gosterilen surum etiketi: `1.2.3 (71)`.
  Future<String> get displayVersion async {
    final info = await packageInfo;
    return '${info.version} (${info.buildNumber})';
  }

  /// Sunucuya `x-app-version` basligiyla giden surum: `1.2.3+71`.
  Future<String> get headerVersion async {
    final info = await packageInfo;
    return headerVersionOf(info.version, info.buildNumber);
  }

  /// Sunucu yalnizca `1.2.3` ya da `1.2.3+71` kabul eder (qulo-server
  /// `utils/client-meta.ts`), gerisini sessizce atar. `displayVersion` bicimi
  /// ("(71)") orada reddedilir; build numarasi bossa `+` eklenmez, cunku
  /// "1.2.3+" de reddedilirdi.
  static String headerVersionOf(String version, String buildNumber) =>
      buildNumber.isEmpty ? version : '$version+$buildNumber';
}
