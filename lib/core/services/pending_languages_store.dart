import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding carousel AUTH ONCESI gosterildiginden, dil secimi authenticated
/// `PUT /users/me/languages` endpoint'ine gonderilemez (401). Secim burada
/// local tutulur; ilk basarili auth'ta [app.dart] listener'i flush eder.
abstract final class PendingLanguagesStore {
  static const _key = 'pending_languages';

  static Future<void> write(List<String> languages) async {
    final prefs = await SharedPreferences.getInstance();
    if (languages.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setStringList(_key, languages);
  }

  static Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
