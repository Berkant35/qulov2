import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/services/pending_languages_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('read boş liste döner (hiç yazılmamışsa)', () async {
    expect(await PendingLanguagesStore.read(), isEmpty);
  });

  test('write sonrası read aynı listeyi döner', () async {
    await PendingLanguagesStore.write(['tr', 'en']);
    expect(await PendingLanguagesStore.read(), ['tr', 'en']);
  });

  test('clear pending diller siler', () async {
    await PendingLanguagesStore.write(['de']);
    await PendingLanguagesStore.clear();
    expect(await PendingLanguagesStore.read(), isEmpty);
  });

  test('boş liste yazımı read tarafında boş döner', () async {
    await PendingLanguagesStore.write([]);
    expect(await PendingLanguagesStore.read(), isEmpty);
  });
}
