import 'package:shared_preferences/shared_preferences.dart';

/// "Bir kez gosterilir" bayraklari (paywall, kutlama, kapatilan kart) icin tek
/// kalici depolama noktasi.
///
/// UI katmani (screen / mixin / widget) `SharedPreferences`'a dogrudan
/// gitmez — bu store uzerinden okur ve yazar.
abstract final class OneTimeFlagStore {
  static Future<bool> isSet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> mark(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  /// Bayrak daha once set edilmemisse set eder ve `true` doner; zaten set ise
  /// hicbir sey yapmaz ve `false` doner. "Ilk kez mi?" kontrolu icin kullanilir.
  static Future<bool> markIfUnset(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return false;
    await prefs.setBool(key, true);
    return true;
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
