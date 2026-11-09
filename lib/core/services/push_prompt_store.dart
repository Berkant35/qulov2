import 'package:shared_preferences/shared_preferences.dart';

/// Bildirim izni açıklama ekranının defteri: ömür boyu EN ÇOK BİR KEZ.
///
/// Reddedene ısrar edilmez (2.0.18): eskiden 3 gün arayla 3 kez soruluyordu;
/// Android 13+ "reddedildi" ile "hiç sorulmadı"yı ayırt ettirmediği için
/// reddeden de tekrar açıklama görüyordu. Kabul eden zaten izinli olur
/// (`canRequestPermission` false). Fikrini değiştiren Ayarlar → Bildirimler'den açar.
/// Anahtar eski sürümle aynı: önceden bir kez görmüş kullanıcı da tekrar görmez.
abstract final class PushPromptStore {
  static const _keyShownCount = 'qulo_push_preprompt_shown_count';

  static Future<bool> isDue() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_keyShownCount) ?? 0) == 0;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyShownCount, (prefs.getInt(_keyShownCount) ?? 0) + 1);
  }
}
