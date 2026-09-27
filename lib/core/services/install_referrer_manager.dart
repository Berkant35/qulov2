import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

/// Play Install Referrer eklentisini saran tek nokta.
///
/// Donanim/ucuncu parti paketler ekran ve widget'lardan dogrudan
/// cagrilmaz; bu sinif eklentiyi tek yerde tutar (CLAUDE.md, DIP).
///
/// Eklenti iOS'ta ve Play Services yoksa **istisna atiyor**, o yuzden hem
/// platform kapisi hem try/catch var: davet kodu okunamamasi kullanicinin
/// akisini bozmamali, sessizce gecilir.
class InstallReferrerManager {
  InstallReferrerManager._();
  static final InstallReferrerManager instance = InstallReferrerManager._();

  /// Kurulumun referrer dizesi; Android disinda ya da okunamazsa `null`.
  ///
  /// Donen deger ham dize (`utm_source=...&utm_content=...`); kodun
  /// cikarilmasi ve dogrulanmasi `core/utils/install_referrer_code.dart`
  /// icinde, test altinda.
  Future<String?> rawReferrer() async {
    if (!Platform.isAndroid) return null;
    try {
      final details = await PlayInstallReferrer.installReferrer;
      return details.installReferrer;
    } catch (e) {
      debugPrint('[InstallReferrer] okunamadi: $e');
      return null;
    }
  }
}
