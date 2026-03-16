import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';

class HapticNotifier extends Notifier<bool> {
  static const _key = 'haptic_enabled';

  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_key);
    if (value != null) {
      state = value;
      HapticManager.instance.setEnabled(value);
    }
  }

  Future<void> toggle() async {
    state = !state;
    HapticManager.instance.setEnabled(state);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

final hapticProvider =
    NotifierProvider<HapticNotifier, bool>(HapticNotifier.new);
