import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/auth_model.dart';

/// Kayıt sözleşmesi (qulo-server d571dc0, 2026-10-04): kayıt token çifti
/// döner, kullanıcı doğrulamadan içeri alınır. Eski sunucu token göndermezse
/// istemci eski akışa (giriş ekranı) düşer.
void main() {
  group('RegisterResponse.tokens', () {
    test('yeni sunucu: token çifti → doğrudan oturum', () {
      final r = RegisterResponse.fromJson(const {
        'userId': 'u1',
        'email': 'a@b.test',
        'accessToken': 'at',
        'refreshToken': 'rt',
        'emailVerified': false,
      });

      expect(r.tokens, const AuthTokens(accessToken: 'at', refreshToken: 'rt', userId: 'u1'));
    });

    test('eski sunucu: token yok → null (giriş ekranına yönlenir)', () {
      final r = RegisterResponse.fromJson(const {'userId': 'u1', 'email': 'a@b.test'});

      expect(r.tokens, isNull);
    });

    test('tek token yetmez', () {
      final r = RegisterResponse.fromJson(const {'userId': 'u1', 'email': 'a@b.test', 'accessToken': 'at'});

      expect(r.tokens, isNull);
    });
  });

  test('ResendVerificationResponse: iki yanıt biçimi', () {
    expect(
      ResendVerificationResponse.fromJson(const {'emailVerified': false, 'sent': true}),
      const ResendVerificationResponse(sent: true),
    );
    expect(
      ResendVerificationResponse.fromJson(const {'emailVerified': true, 'sent': false}).emailVerified,
      isTrue,
    );
  });
}
