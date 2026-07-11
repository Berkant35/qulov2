/// Hesap silme retention teklifi uygunluk yanıtı.
/// GET /users/me/retention/eligibility → { eligible, amount }
class RetentionEligibilityModel {
  final bool eligible;
  final int amount;

  const RetentionEligibilityModel({required this.eligible, required this.amount});

  factory RetentionEligibilityModel.fromJson(Map<String, dynamic> json) {
    return RetentionEligibilityModel(
      eligible: json['eligible'] == true,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}
