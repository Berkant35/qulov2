import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/features/email_verification/widgets/email_verification_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// "Tekrar gönder" sonucu — sayfa metni ve GA4 `result` parametresi buradan.
enum ResendOutcome {
  sent('sent'),
  alreadyVerified('already_verified'),
  rateLimited('rate_limited'),
  failed('failed');

  const ResendOutcome(this.analyticsValue);
  final String analyticsValue;
}

/// Doğrulama sayfasının açıldığı an (GA4 `trigger`).
abstract final class EmailVerifyTrigger {
  static const String message = 'message';
  static const String media = 'media';
  static const String mediaRequest = 'media_request';
  static const String question = 'question';
  static const String redeem = 'redeem';
  static const String banner = 'banner';
}

/// E-posta doğrulama kapısı (2026-10-04, qulo-server d571dc0).
///
/// Kayıt artık token döndürüyor: kullanıcı doğrulamadan içeri giriyor, Keşfet ve
/// quiz serbest. Sunucu yalnız eşleşmeye yazan uçlarda (mesaj, medya, sohbet
/// sorusu, medya isteği, hediye kartı) doğrulanmamışa 403
/// `EMAIL_VERIFICATION_REQUIRED` dönüyor. Tek doğru kaynak sunucu: istemci
/// önceden engellemez, kapı hatası gelince sayfayı açar.
class EmailVerificationController {
  EmailVerificationController(this._ref);

  final Ref _ref;
  bool _promptOpen = false;

  static const requiredCode = 'EMAIL_VERIFICATION_REQUIRED';

  static bool isRequired(AppFailure failure) =>
      failure is ServerFailure && failure.code == requiredCode;

  bool get _isVerified => _ref.read(userProvider).valueOrNull?.emailVerified == true;

  /// Kapı hatasıysa doğrulama sayfasını açar ve `true` döner — çağıran genel
  /// hata mesajını göstermez. Başka hata → `false`, sayfa açılmaz.
  Future<bool> handleFailure(AppFailure failure, {required String trigger}) async {
    if (!isRequired(failure)) return false;
    await prompt(trigger: trigger);
    return true;
  }

  /// Doğrulama sayfası. `true` = kapanışta doğrulanmış (kullanıcı asıl eylemi
  /// tekrar deneyebilir). Aynı anda ikinci sayfa açılmaz.
  Future<bool> prompt({required String trigger}) async {
    if (_promptOpen) return false;
    _promptOpen = true;
    try {
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.emailVerifyPromptShow,
        params: {AnalyticsEvents.paramTrigger: trigger},
      );
      final verified = await _ref.read(navigationServiceProvider).showAppBottomSheet<bool>(
            CustomBottomSheet(
              name: 'email_verification',
              builder: (_) => EmailVerificationSheet(trigger: trigger),
            ),
          );
      return verified == true;
    } finally {
      _promptOpen = false;
    }
  }

  /// Doğrulama e-postasını yeniden ister. Zaten doğrulanmışsa profil tazelenir.
  Future<ResendOutcome> resend() async {
    final result = await _ref.read(authRepositoryProvider).resendVerification();
    final outcome = switch (result) {
      Success(:final data) when data.emailVerified => ResendOutcome.alreadyVerified,
      Success(:final data) when data.sent => ResendOutcome.sent,
      Success() => ResendOutcome.failed,
      Failure(failure: ServerFailure(code: 'RATE_LIMITED')) => ResendOutcome.rateLimited,
      Failure() => ResendOutcome.failed,
    };
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.emailVerifyResend,
      params: {AnalyticsEvents.paramResult: outcome.analyticsValue},
    );
    if (outcome == ResendOutcome.alreadyVerified) {
      await _ref.read(userProvider.notifier).fetchMe();
    }
    return outcome;
  }

  /// "Doğruladım": profili tazeler, sunucu doğrulanmış diyorsa `true`.
  Future<bool> confirmVerified({required String trigger}) async {
    await _ref.read(userProvider.notifier).fetchMe();
    final verified = _isVerified;
    if (verified) {
      AnalyticsManager.instance.logEvent(
        AnalyticsEvents.emailVerifyConfirmed,
        params: {AnalyticsEvents.paramTrigger: trigger},
      );
    }
    return verified;
  }

  /// Uygulama öne gelince: bağlantıya tıklayıp dönen kullanıcının kapısı açılsın.
  /// Doğrulanmış (ya da yüklenmemiş) kullanıcıda istek atılmaz.
  Future<void> refreshIfUnverified() async {
    final user = _ref.read(userProvider).valueOrNull;
    if (user == null || user.emailVerified) return;
    await _ref.read(userProvider.notifier).fetchMe();
  }
}

final emailVerificationControllerProvider =
    Provider<EmailVerificationController>(EmailVerificationController.new);
