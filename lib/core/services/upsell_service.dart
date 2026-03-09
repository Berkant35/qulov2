import 'package:shared_preferences/shared_preferences.dart';

class UpsellService {
  static const _maxUpsellsPerSession = 2;
  static int _sessionUpsellCount = 0;

  static const _keyOnboardingShown = 'upsell_onboarding_shown';
  static const _keyFirstMatchShown = 'upsell_first_match_shown';
  static const _keyDay3Shown = 'upsell_day3_shown';
  static const _keyLastDiamondEmpty = 'upsell_last_diamond_empty';
  static const _keyLastBoostNeed = 'upsell_last_boost_need';

  static Future<bool> shouldShowOnboarding() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyOnboardingShown) ?? false);
  }

  static Future<void> markOnboardingShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingShown, true);
  }

  static Future<bool> shouldShowDiamondEmpty() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_keyLastDiamondEmpty) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastShown;
    return elapsed > 24 * 60 * 60 * 1000;
  }

  static Future<void> markDiamondEmptyShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastDiamondEmpty,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> shouldShowFirstMatch() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyFirstMatchShown) ?? false);
  }

  static Future<void> markFirstMatchShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstMatchShown, true);
  }

  static Future<bool> shouldShowSwipeLimit() async {
    return _sessionUpsellCount < _maxUpsellsPerSession;
  }

  static Future<bool> shouldShowDay3Offer(DateTime registeredAt) async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyDay3Shown) ?? false) return false;
    final daysSince = DateTime.now().difference(registeredAt).inDays;
    return daysSince >= 3;
  }

  static Future<void> markDay3Shown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDay3Shown, true);
  }

  static Future<bool> shouldShowBoostNeed() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_keyLastBoostNeed) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastShown;
    return elapsed > 12 * 60 * 60 * 1000;
  }

  static Future<void> markBoostNeedShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastBoostNeed,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static void resetSession() {
    _sessionUpsellCount = 0;
  }
}
