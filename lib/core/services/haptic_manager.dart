import 'package:flutter/services.dart';

/// Singleton manager for haptic feedback.
/// Usage: HapticManager.instance.light() or via hapticManagerProvider.
class HapticManager {
  HapticManager._();
  static final HapticManager instance = HapticManager._();

  bool _enabled = true;

  bool get isEnabled => _enabled;

  void setEnabled(bool value) => _enabled = value;

  /// Light tap — button presses, selections
  Future<void> light() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium tap — card swipes, toggles
  Future<void> medium() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap — destructive actions, important confirmations
  Future<void> heavy() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection tick — picker scrolls, segment changes
  Future<void> selection() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Success vibration pattern — quiz correct, match found
  Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error vibration — wrong answer, failed action
  Future<void> error() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Warning vibration — undo, limit reached
  Future<void> warning() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }
}
