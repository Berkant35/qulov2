import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/translations/en.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';

/// Hata snackbar'lari ham `AppFailure.message` gostermez.
///
/// Sunucu hata govdesinde mesaj gondermiyor; `message` dolu gelen tek yer
/// istemci varsayilanlari (Ingilizce sabit). Mobil agda kopma sik: eskiden
/// guc/satin alma/sohbet sorusu snackbar'lari her dilde "No internet
/// connection" yaziyordu.
void main() {
  group('userMessageKey', () {
    test('ag hatasi kendi anahtarina gider — varsayilan Ingilizce mesaj dolu olsa bile', () {
      const f = NetworkFailure();
      expect(f.message, isNotNull);

      expect(f.userMessageKey('purchase_failed'), 'error_no_connection');
    });

    test('zaman asimi kendi anahtarina gider', () {
      expect(const TimeoutFailure().userMessageKey('purchase_failed'), 'error_timeout');
    });

    test('rate limit (429, sunucu rateLimitResponse) kendi anahtarina gider', () {
      const f = ServerFailure(code: 'RATE_LIMITED', statusCode: 429);

      expect(f.userMessageKey('purchase_failed'), 'error_rate_limited');
    });

    test('e-posta dogrulama kapisi (403) genel hata yerine ne yapilacagini soyler', () {
      const f = ServerFailure(code: 'EMAIL_VERIFICATION_REQUIRED', statusCode: 403);

      expect(f.userMessageKey('chat_question_send_failed'), 'error_email_verification_required');
    });

    test('tercih rizasi kodlari (sunucu 403/409) kendi anahtarlarina gider', () {
      const cases = {
        'GENDER_PREF_LOCKED': 'error_gender_pref_locked',
        'CONSENT_RELOCK': 'error_consent_relock',
        'NOT_COMPATIBLE': 'error_not_compatible',
        // Sunucu erişilemeyen profili tek tip 404 USER_NOT_FOUND ile döner.
        'USER_NOT_FOUND': 'error_not_compatible',
      };

      for (final entry in cases.entries) {
        final f = ServerFailure(code: entry.key, statusCode: 403);

        expect(f.userMessageKey('error_general'), entry.value, reason: entry.key);
        expect(enTranslations.keys, contains(entry.value));
      }
    });

    test('kimlik etiketi kodlari (sunucu 400/409) kendi anahtarlarina gider', () {
      const cases = {
        ('IDENTITY_CONSENT_REQUIRED', 400): 'error_identity_consent_required',
        ('GENDER_LOCKED', 409): 'error_gender_locked',
      };

      for (final entry in cases.entries) {
        final (code, status) = entry.key;
        final f = ServerFailure(code: code, statusCode: status);

        expect(f.userMessageKey('error_general'), entry.value, reason: code);
        expect(enTranslations.keys, contains(entry.value));
      }
    });

    test('sunucu hatasi cagiranin anahtarina duser — mesaj gelse bile ham gosterilmez', () {
      const f = ServerFailure(code: 'SERVER_ERROR', statusCode: 500, message: 'Internal error');

      expect(f.userMessageKey('error_general'), 'error_general');
    });

    test('ic hata metni (UnknownFailure) kullaniciya gitmez', () {
      const f = UnknownFailure(message: 'No active session');

      expect(f.userMessageKey('quiz_power_failed'), 'quiz_power_failed');
    });

    test('yetkisiz hata cagiranin anahtarina duser', () {
      expect(const UnauthorizedFailure().userMessageKey('error_general'), 'error_general');
    });

    test('yeni anahtarlar ceviride var (parite testi 18 dile yayar)', () {
      expect(enTranslations.keys, containsAll(['error_no_connection', 'error_timeout']));
    });
  });

  test('kaynak tarama: lib/features icinde ham failure.message gosterimi yok', () {
    // Iki bicim: `f.message ?? ...` ve metne gomulu `'...: $failure'`
    // (2026-09-13: sohbet sorusu gonderme/taslak snackbar'lari boyleydi).
    final rawMessage = RegExp(r'\b\w+\.message\s*\?\?|\$\{?(failure|error)\b');
    final offenders = [
      for (final f in Directory('lib/features').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart'))
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (rawMessage.hasMatch(line)) '${f.path}:${i + 1}: ${line.trim()}',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
