import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/email_verification/email_verification_controller.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import 'fakes.dart';

/// E-posta doğrulama kapısı (qulo-server d571dc0): doğrulamasız giriş serbest,
/// eşleşmeye yazmak 403 `EMAIL_VERIFICATION_REQUIRED`. Kapı istemcide yalnız
/// bu koda tepki verir; diğer hatalar eskisi gibi çağırana kalır.
void main() {
  late ScriptedUserNotifier user;
  late FakeResendAuthRepository auth;
  late RecordingNavigationService nav;
  late ProviderContainer container;

  Future<EmailVerificationController> setUpController({
    UserModel? initial = unverified,
    UserModel? afterFetch,
    Result<ResendVerificationResponse> resend = const Success(ResendVerificationResponse(sent: true)),
    Object? sheetResult,
  }) async {
    user = ScriptedUserNotifier(initial, afterFetch: afterFetch);
    auth = FakeResendAuthRepository(resend);
    nav = RecordingNavigationService(sheetResult: sheetResult);
    container = ProviderContainer(overrides: [
      userProvider.overrideWith(() => user),
      authRepositoryProvider.overrideWithValue(auth),
      navigationServiceProvider.overrideWithValue(nav),
    ]);
    addTearDown(container.dispose);
    await container.read(userProvider.future);
    return container.read(emailVerificationControllerProvider);
  }

  group('handleFailure — yalnız kapı kodu sayfa açar', () {
    test('403 EMAIL_VERIFICATION_REQUIRED → doğrulama sayfası, true', () async {
      final c = await setUpController();

      final gated = await c.handleFailure(
        const ServerFailure(code: 'EMAIL_VERIFICATION_REQUIRED', statusCode: 403),
        trigger: EmailVerifyTrigger.message,
      );

      expect(gated, isTrue);
      expect(nav.sheets, ['email_verification']);
    });

    for (final failure in <AppFailure>[
      const NetworkFailure(),
      const ServerFailure(code: 'CHAT_LOCKED', statusCode: 403),
      const ServerFailure(code: 'SERVER_ERROR', statusCode: 500),
    ]) {
      test('başka hata (${failure is ServerFailure ? failure.code : failure.runtimeType}) → sayfa yok, false', () async {
        final c = await setUpController();

        expect(await c.handleFailure(failure, trigger: EmailVerifyTrigger.message), isFalse);
        expect(nav.sheets, isEmpty);
      });
    }

    test('prompt sonucu: sayfa true ile kapanırsa doğrulandı', () async {
      final c = await setUpController(sheetResult: true);

      expect(await c.prompt(trigger: EmailVerifyTrigger.banner), isTrue);
    });
  });

  group('resend — sunucu yanıtı → sonuç', () {
    test('gönderildi', () async {
      final c = await setUpController();

      expect(await c.resend(), ResendOutcome.sent);
      expect(user.fetchCalls, 0);
    });

    test('zaten doğrulanmış → profil tazelenir (kapı açılsın)', () async {
      final c = await setUpController(
        resend: const Success(ResendVerificationResponse(emailVerified: true)),
        afterFetch: verified,
      );

      expect(await c.resend(), ResendOutcome.alreadyVerified);
      expect(user.fetchCalls, 1);
      expect(container.read(userProvider).valueOrNull?.emailVerified, isTrue);
    });

    test('429 RATE_LIMITED → "biraz sonra dene"', () async {
      final c = await setUpController(
        resend: const Failure(ServerFailure(code: 'RATE_LIMITED', statusCode: 429)),
      );

      expect(await c.resend(), ResendOutcome.rateLimited);
    });

    test('500 / ağ → tekrar dene', () async {
      final c = await setUpController(
        resend: const Failure(ServerFailure(code: 'SERVER_ERROR', statusCode: 500)),
      );
      expect(await c.resend(), ResendOutcome.failed);
    });
  });

  group('confirmVerified — "Doğruladım"', () {
    test('sunucu doğrulanmış diyorsa true', () async {
      final c = await setUpController(afterFetch: verified);

      expect(await c.confirmVerified(trigger: EmailVerifyTrigger.message), isTrue);
      expect(user.fetchCalls, 1);
    });

    test('hâlâ doğrulanmamışsa false', () async {
      final c = await setUpController(afterFetch: unverified);

      expect(await c.confirmVerified(trigger: EmailVerifyTrigger.message), isFalse);
    });
  });

  group('refreshIfUnverified — uygulama öne gelince', () {
    test('doğrulanmamış kullanıcı → /me tazelenir', () async {
      final c = await setUpController(afterFetch: verified);

      await c.refreshIfUnverified();

      expect(user.fetchCalls, 1);
    });

    test('doğrulanmış kullanıcı → istek yok (her resume\'da /me atılmaz)', () async {
      final c = await setUpController(initial: verified);

      await c.refreshIfUnverified();

      expect(user.fetchCalls, 0);
    });

    test('profil yüklenmemiş → istek yok', () async {
      final c = await setUpController(initial: null);

      await c.refreshIfUnverified();

      expect(user.fetchCalls, 0);
    });
  });
}
