import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/features/auth/mixins/social_auth_mixin.dart';

/// Sosyal girişte 409 EMAIL_ALREADY_EXISTS (qulo-server d571dc0): Google
/// e-postayı doğrulamamış ve aynı adresle e-posta hesabı var — sunucu
/// bağlamıyor. Kayıt ekranındaki "bu e-posta kayıtlı" metni burada yanıltıcı.
void main() {
  test('EMAIL_ALREADY_EXISTS sosyal girişe özgü koda çevrilir', () {
    expect(socialAuthErrorCode('EMAIL_ALREADY_EXISTS'), 'SOCIAL_EMAIL_ALREADY_EXISTS');
    expect(socialAuthErrorCode('ACCOUNT_BANNED'), 'ACCOUNT_BANNED');
  });

  test('çevrilen kodun kendi metni var (genel hataya düşmez)', () {
    final en = AppLocalizations(const Locale('en'));
    final message = en.errorMessage(socialAuthErrorCode('EMAIL_ALREADY_EXISTS'));

    expect(message, en.get('error_social_email_already_exists'));
    expect(message, isNot(en.get('error_unknown')));
  });
}
