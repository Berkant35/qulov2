import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// main.dart'ta preload edilmis SharedPreferences — router redirect ILK FRAME'de
/// senkron okuyabilsin diye override ile inject edilir.
final onboardingSeenPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main.dart override etmeli'),
);

/// Onboarding carousel'in gorulup gorulmedigini senkron tutar. Router auth-oncesi
/// guard'i bunu `ref.read` ile okur. Key mevcut `onboarding_v2_seen` — gecmiste
/// carousel gormus kullanici tekrar gormez.
class OnboardingSeenNotifier extends Notifier<bool> {
  static const key = 'onboarding_v2_seen';

  @override
  bool build() {
    final prefs = ref.read(onboardingSeenPrefsProvider);
    return (prefs.getBool(key) ?? false) ||
        (prefs.getBool('onboarding_questions_seen') ?? false);
  }

  Future<void> markSeen() async {
    state = true;
    final prefs = ref.read(onboardingSeenPrefsProvider);
    await prefs.setBool(key, true);
    await prefs.setBool('onboarding_questions_seen', true); // legacy tutarlilik
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, bool>(OnboardingSeenNotifier.new);
