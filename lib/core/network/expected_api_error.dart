import 'package:dio/dio.dart';

/// Sunucunun bilerek döndürdüğü iş kuralı yanıtı mı (Crashlytics'e yazılmaz)?
///
/// Yalnız 4xx + gövdede ([error.code]) aşağıdaki listede olan kod. Liste
/// bilinçli olarak AÇIK yazılır: tanımadığımız kod, kodsuz 4xx, istemci
/// hatası sinyali veren kodlar (VALIDATION_ERROR, INVALID_*, FORBIDDEN,
/// *_NOT_FOUND, RATE_LIMITED, INVALID_RECEIPT) ve tüm 5xx raporlanmaya devam eder.
bool isExpectedBusinessError(DioException err) {
  if (err.type != DioExceptionType.badResponse) return false;
  final status = err.response?.statusCode;
  if (status == null || status < 400 || status >= 500) return false;
  final data = err.response?.data;
  if (data is! Map) return false;
  final error = data['error'];
  return error is Map && expectedBusinessErrorCodes.contains(error['code']);
}

/// qulo-server `AppError` kodları — kullanıcı durumundan doğan, UI'ın zaten
/// karşıladığı yanıtlar. Yeni iş kuralı kodu eklendiğinde buraya da eklenir.
const expectedBusinessErrorCodes = <String>{
  // Limit / ekonomi
  'DAILY_LIMIT_EXCEEDED',
  'INSUFFICIENT_DIAMONDS',
  'DIAMOND_COOLDOWN',
  'MAX_PHOTOS_REACHED',
  'MAX_QUESTIONS_REACHED',
  'REFERRAL_LIMIT_REACHED',
  'REWARD_MONTHLY_CAP',
  'PAGE_SECTION_LIMIT',
  'PAGE_SECTION_ITEM_LIMIT',
  // Profil / hesap ön koşulları (Discover 400 konum yok = PROFILE_INCOMPLETE)
  'EMAIL_VERIFICATION_REQUIRED',
  'PROFILE_INCOMPLETE',
  'PROFILE_NOT_COMPLETE',
  'GENDER_PREF_REQUIRED',
  'IDENTITY_CONSENT_REQUIRED',
  'NO_QUESTIONS',
  'PAGE_SECTION_IMAGE_REQUIRED',
  'UNDERAGE_USER',
  'ACCOUNT_BANNED',
  // Abonelik kapıları
  'PASSPORT_REQUIRES_PREMIUM',
  'PASSPORT_ALREADY_ACTIVE',
  'RAINBOW_NOT_AVAILABLE',
  // Kilitli / tekrarlanan işlem (idempotency)
  'GENDER_LOCKED',
  'GENDER_PREF_LOCKED',
  'CONSENT_RELOCK',
  'ALREADY_SWIPED',
  'ALREADY_ANSWERED',
  'ALREADY_BLOCKED',
  'ALREADY_REFERRED',
  'BADGE_ALREADY_CLAIMED',
  'BADGE_THRESHOLD_NOT_MET',
  'POWER_ALREADY_USED',
  'QUIZ_RETRY_LOCKED',
  'DUPLICATE_TRANSACTION',
  'DUPLICATE_RECEIPT',
  'RETENTION_NOT_ELIGIBLE',
  'SELF_REFERRAL',
  'INVALID_REFERRAL_CODE',
  'REWARD_ACCOUNT_TOO_NEW',
  'REWARD_ACCOUNT_PURGED',
  'REWARD_ITEM_UNAVAILABLE',
  // Quiz / sohbet durumu
  'TIME_UP',
  'SESSION_EXPIRED',
  'MATCH_INACTIVE',
  'NOT_MATCHED',
  'NOT_COMPATIBLE',
  'CHAT_LOCKED',
  'USER_BLOCKED',
  'MEDIA_NOT_ENABLED',
  'MEDIA_ALREADY_ENABLED',
  'MEDIA_REQUEST_PENDING',
  // Kimlik doğrulama: kullanıcı girdisi
  'EMAIL_ALREADY_EXISTS',
  'SOCIAL_ACCOUNT_EXISTS',
  'SOCIAL_LOGIN_ONLY',
  'PASSWORD_LOGIN_ONLY',
};
