import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/push_prompt_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bildirim izni açıklama ekranı ömür boyu bir kez (2.0.18: reddedene ısrar yok).
/// Eski kural (3 gün arayla 3 kez) bilerek kaldırıldı — test bayat değil, kural değişti.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('hiç gösterilmediyse gösterilebilir', () async {
    expect(await PushPromptStore.isDue(), isTrue);
  });

  test('bir kez gösterildikten sonra bir daha gösterilmez (süre geçse de)', () async {
    await PushPromptStore.markShown();

    expect(await PushPromptStore.isDue(), isFalse);
  });

  test('eski sürümde görmüş kullanıcı (sayaç > 0) tekrar görmez', () async {
    SharedPreferences.setMockInitialValues({'qulo_push_preprompt_shown_count': 2});

    expect(await PushPromptStore.isDue(), isFalse);
  });
}
