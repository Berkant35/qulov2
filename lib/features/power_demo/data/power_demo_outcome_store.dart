import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_outcome.dart';

/// Onboarding güç demosunun sonucu (`completed` / `skipped:N`) — cihazda saklanır.
///
/// Demo AUTH ÖNCESİ oynandığından o anki olaylar yalnız Firebase'e gider; sonuç burada
/// durur, kayıt/girişten sonra `PowerDemoOutcomeReporter` bir kez raporlar (spec §9.2).
///
/// Yalnız **onboarding** sonucu yazılır (market / quiz_intro denemeleri sonucu değiştirmez)
/// ve **ilk yazılan korunur**: kullanıcı carousel'i yeniden görse de karşılaştırma grubu
/// ("demoyu ilk görüşünde ne yaptı") kaymaz.
abstract final class PowerDemoOutcomeStore {
  static const String _key = 'power_demo_outcome_v1';

  /// [outcome] geçerli ve henüz geçerli bir sonuç yoksa yazar. [PowerDemoNotSeen] yazılmaz
  /// (anahtar oluşmaz); bozuk kayıt "yok" sayılıp üzerine yazılır.
  static Future<void> saveOnboarding(PowerDemoOutcome outcome) async {
    final code = outcome.encode();
    if (code == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (_decode(prefs) is! PowerDemoNotSeen) return;
    await prefs.setString(_key, code);
  }

  /// Kayıt yok / bozuk / yanlış türde → [PowerDemoNotSeen] (demoyu çökertmez).
  static Future<PowerDemoOutcome> read() async =>
      _decode(await SharedPreferences.getInstance());

  static PowerDemoOutcome _decode(SharedPreferences prefs) {
    final raw = prefs.get(_key);
    return PowerDemoOutcome.decode(raw is String ? raw : null);
  }
}
