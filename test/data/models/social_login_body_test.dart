import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/social_login_body.dart';

/// `/auth/social-login` gövde haritası: mevcut tel formatı (provider/id_token +
/// opsiyonel name/surname/nonce yalnızca doluysa) korunur, artık `locale` de eklenir (I4).
void main() {
  test('zorunlu alanlar + locale; opsiyonel alanlar null iken haritada yok', () {
    final body = buildSocialLoginBody(
      provider: 'google',
      idToken: 'tok123',
      locale: 'tr',
    );
    expect(body, {
      'provider': 'google',
      'id_token': 'tok123',
      'locale': 'tr',
    });
  });

  test('opsiyonel alanlar (name/surname/nonce) doluyken haritaya eklenir', () {
    final body = buildSocialLoginBody(
      provider: 'apple',
      idToken: 'tok456',
      name: 'Ada',
      surname: 'Lovelace',
      nonce: 'n0nce',
      locale: 'en',
    );
    expect(body, {
      'provider': 'apple',
      'id_token': 'tok456',
      'name': 'Ada',
      'surname': 'Lovelace',
      'nonce': 'n0nce',
      'locale': 'en',
    });
  });

  test('name doluyken surname/nonce null: sadece name eklenir', () {
    final body = buildSocialLoginBody(
      provider: 'apple',
      idToken: 'tok789',
      name: 'Ada',
      locale: 'de',
    );
    expect(body, {
      'provider': 'apple',
      'id_token': 'tok789',
      'name': 'Ada',
      'locale': 'de',
    });
  });
}
