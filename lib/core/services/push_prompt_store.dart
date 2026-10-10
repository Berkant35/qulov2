import 'package:shared_preferences/shared_preferences.dart';

/// Bildirim izni açıklama ekranının sıklık defteri: ömür boyu en çok
/// [maxShown] kez, aralarında en az [cooldown]. İlk eşleşme ile ilk mesaj
/// çoğu zaman dakikalar arayla gelir; reddeden kullanıcıya aynı oturumda
/// ikinci kez sorulmaz.
abstract final class PushPromptStore {
  static const _keyShownCount = 'qulo_push_preprompt_shown_count';
  static const _keyLastShown = 'qulo_push_preprompt_last_shown';

  static const int maxShown = 3;
  static const Duration cooldown = Duration(days: 3);

  static Future<bool> isDue({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_keyShownCount) ?? 0) >= maxShown) return false;
    final last = DateTime.tryParse(prefs.getString(_keyLastShown) ?? '');
    if (last == null) return true;
    return (now ?? DateTime.now()).difference(last) >= cooldown;
  }

  static Future<void> markShown({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyShownCount, (prefs.getInt(_keyShownCount) ?? 0) + 1);
    await prefs.setString(_keyLastShown, (now ?? DateTime.now()).toIso8601String());
  }
}
