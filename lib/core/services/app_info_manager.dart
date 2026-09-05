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

  Future<String> get buildNumber async => (await packageInfo).buildNumber;

  /// Ayarlar ekraninda gosterilen surum etiketi: `1.2.3 (71)`.
  Future<String> get displayVersion async {
    final info = await packageInfo;
    return '${info.version} (${info.buildNumber})';
  }
}
