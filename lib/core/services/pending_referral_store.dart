import 'package:shared_preferences/shared_preferences.dart';

/// Kurulumla gelen davet kodunu, uygulanabilecegi ana kadar tutar.
///
/// Kod cihaza kurulum aninda ulasiyor (Play Install Referrer) ama
/// `POST /referrals/apply` kimlik istiyor; yani kod auth'tan ONCE elde edilip
/// sonra kullanilmak zorunda. Ayni sekil `PendingLanguagesStore` ile birebir:
/// auth oncesi yakalanan deger, ilk basarili auth'ta `app.dart` listener'i
/// tarafindan flush edilir.
///
/// Referrer yalnizca BIR KEZ okunur ([markReferrerRead]): Play ayni degeri
/// her acilista donuyor, ve kullanici davetten vazgecip kodu sildikten sonra
/// tekrar okunmasi onu geri getirir.
abstract final class PendingReferralStore {
  static const _codeKey = 'pending_referral_code';
  static const _readKey = 'install_referrer_read';

  /// Referrer daha once basariyla okundu mu?
  static Future<bool> wasReferrerRead() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_readKey) ?? false;
  }

  /// Okuma BASARILI olduktan sonra isaretlenir.
  ///
  /// Once "okumaya basladim" anlaminda isaretleniyordu; Play Services yoksa ya
  /// da okuma gecici olarak patlarsa bayrak yine yaziliyor ve kod bir daha hic
  /// okunmuyordu — gercek bir davet kurulumunda odul kalici olarak kayboluyor.
  static Future<void> markReferrerRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readKey, true);
  }

  static Future<void> write(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeKey, code);
  }

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_codeKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codeKey);
  }
}
