import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/features/power_demo/data/power_demo_outcome_store.dart';
import 'package:qulo_v2/features/power_demo/domain/power_demo_outcome.dart';

/// Onboarding demosu auth ÖNCESİ oynandığından sonuç cihazda saklanır, kayıttan sonra
/// raporlanır (spec §9.2). Yalnız onboarding sonucu yazılır; ilk yazılan korunur.
void main() {
  const key = 'power_demo_outcome_v1';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('boş → notSeen', () async {
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoNotSeen());
  });

  test('onboarding sonucu yazılır ve okunur (completed / skipped)', () async {
    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoSkipped(3));
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(3));

    SharedPreferences.setMockInitialValues({});
    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoCompleted());
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoCompleted());
  });

  test('ilk onboarding sonucu korunur, ikinci yazılmaz', () async {
    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoSkipped(3));
    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoCompleted());

    expect(await PowerDemoOutcomeStore.read(), const PowerDemoSkipped(3));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(key), 'skipped:3');
  });

  test('completed ilk yazıldıysa sonradan skipped onu bozmaz', () async {
    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoCompleted());
    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoSkipped(1));

    expect(await PowerDemoOutcomeStore.read(), const PowerDemoCompleted());
  });

  test('notSeen yazılmaz (anahtar oluşmaz)', () async {
    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoNotSeen());

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(key), isFalse);
  });

  test('bozuk kayıt notSeen sayılır ve gerçek sonucun üzerine yazılabilir', () async {
    SharedPreferences.setMockInitialValues({key: 'çöp'});
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoNotSeen());

    await PowerDemoOutcomeStore.saveOnboarding(const PowerDemoCompleted());
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoCompleted());
  });

  test('anahtar yanlış türdeyse çökmez, notSeen döner', () async {
    SharedPreferences.setMockInitialValues({key: 42});
    expect(await PowerDemoOutcomeStore.read(), const PowerDemoNotSeen());
  });
}
