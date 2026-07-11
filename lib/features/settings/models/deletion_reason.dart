/// Hesap silme nedenleri (churn taksonomisi).
/// `code` server'a gönderilir (canonical, dil-bağımsız); `labelKey` UI etiketinin l10n anahtarı.
/// UI sırası sabit — analizi kolaylaştırır, randomize edilmez.
/// Spec: docs/superpowers/specs/2026-06-27-account-deletion-reasons-design.md
enum DeletionReason {
  foundSomeone('found_someone', 'delete_reason_found_someone'),
  fewMatches('few_matches', 'delete_reason_few_matches'),
  fewUsersNearby('few_users_nearby', 'delete_reason_few_users_nearby'),
  appConfusing('app_confusing', 'delete_reason_app_confusing'),
  technicalIssues('technical_issues', 'delete_reason_technical_issues'),
  privacyConcerns('privacy_concerns', 'delete_reason_privacy_concerns'),
  tooExpensive('too_expensive', 'delete_reason_too_expensive'),
  takingABreak('taking_a_break', 'delete_reason_taking_a_break'),
  other('other', 'delete_reason_other');

  const DeletionReason(this.code, this.labelKey);

  final String code;
  final String labelKey;
}

/// Kullanıcı atladığında gönderilen kod (UI'da neden olarak görünmez).
const String kDeletionReasonSkipped = 'skipped';

/// DeleteReasonSheet sonucu. `null` dönerse kullanıcı akışı iptal etti.
class DeleteReasonResult {
  /// Canonical reason kodu — bir [DeletionReason.code] ya da [kDeletionReasonSkipped].
  final String reasonCode;

  /// Sadece `other` seçildiğinde dolu olabilen opsiyonel serbest metin.
  final String? reasonText;

  const DeleteReasonResult({required this.reasonCode, this.reasonText});
}
