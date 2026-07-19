import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';

void main() {
  test('prefs true ise initial state true (senkron okuma)', () async {
    SharedPreferences.setMockInitialValues({'onboarding_v2_seen': true});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      onboardingSeenPrefsProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    expect(container.read(onboardingSeenProvider), isTrue);
  });

  test('prefs boş ise initial state false', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      onboardingSeenPrefsProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    expect(container.read(onboardingSeenProvider), isFalse);
  });

  test('markSeen state true yapar ve prefs yazar', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      onboardingSeenPrefsProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    await container.read(onboardingSeenProvider.notifier).markSeen();
    expect(container.read(onboardingSeenProvider), isTrue);
    expect(prefs.getBool('onboarding_v2_seen'), isTrue);
  });
}
