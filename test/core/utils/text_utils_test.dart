import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/utils/text_utils.dart';

/// Bildirim gövdesi: çözülmemiş {placeholder} silinir; boş kalırsa çevrilmiş fallback.
void main() {
  test('placeholder temizlenir ve boşluklar sıkışır', () {
    expect(sanitizeNotificationBody('Merhaba {name} !', fallback: 'x'), 'Merhaba !');
  });

  test('boş kalırsa fallback döner (hardcoded Türkçe yok)', () {
    expect(sanitizeNotificationBody('{name}', fallback: 'New notification'), 'New notification');
  });
}
