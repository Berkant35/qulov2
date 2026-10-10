import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/push_prompt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bildirim izni açıklama ekranının sıklık sınırı.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final t0 = DateTime(2026, 10, 3, 12);

  test('hiç gösterilmediyse gösterilebilir', () async {
    expect(await PushPromptStore.isDue(now: t0), isTrue);
  });

  test('gösterildikten sonra soğuma dolana kadar gösterilmez', () async {
    await PushPromptStore.markShown(now: t0);

    expect(await PushPromptStore.isDue(now: t0.add(const Duration(minutes: 5))), isFalse);
    expect(
      await PushPromptStore.isDue(now: t0.add(PushPromptStore.cooldown)),
      isTrue,
    );
  });

  test('ömür boyu üst sınıra ulaşınca bir daha gösterilmez', () async {
    var t = t0;
    for (var i = 0; i < PushPromptStore.maxShown; i++) {
      await PushPromptStore.markShown(now: t);
      t = t.add(PushPromptStore.cooldown);
    }

    expect(await PushPromptStore.isDue(now: t.add(const Duration(days: 365))), isFalse);
  });
}
