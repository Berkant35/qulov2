import 'package:equatable/equatable.dart';

class SubscriptionStatusResponse {
  final SubscriptionInfo subscription;
  final SubscriptionLimits limits;

  const SubscriptionStatusResponse({
    required this.subscription,
    required this.limits,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      subscription: json['subscription'] != null
          ? SubscriptionInfo.fromJson(json['subscription'] as Map<String, dynamic>)
          : SubscriptionInfo.free(),
      limits: json['limits'] != null
          ? SubscriptionLimits.fromJson(json['limits'] as Map<String, dynamic>)
          : const SubscriptionLimits(
              dailyDiscovers: 50,
              maxQuestions: 4,
              dailyUndos: 0,
              monthlyPurpleBonus: 0,
              passportMode: false,
              hasAds: true,
            ),
    );
  }
}

class SubscriptionInfo extends Equatable {
  final String? plan;
  final String? status;
  final String? expiresAt;
  final bool isActive;

  const SubscriptionInfo({
    this.plan,
    this.status,
    this.expiresAt,
    this.isActive = false,
  });

  bool get isPlus => isActive && plan == 'plus';
  bool get isPremium => isActive && plan == 'premium';
  bool get isFree => !isActive;
  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] as String?,
      status: json['status'] as String?,
      expiresAt: json['expiresAt'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  factory SubscriptionInfo.free() => const SubscriptionInfo();

  @override
  List<Object?> get props => [plan, status, expiresAt, isActive];
}

class SubscriptionLimits extends Equatable {
  final int dailyDiscovers;
  final int maxQuestions;
  final int dailyUndos;
  final int monthlyPurpleBonus;
  final bool passportMode;
  final bool hasAds;

  const SubscriptionLimits({
    required this.dailyDiscovers,
    required this.maxQuestions,
    required this.dailyUndos,
    required this.monthlyPurpleBonus,
    required this.passportMode,
    required this.hasAds,
  });

  factory SubscriptionLimits.fromJson(Map<String, dynamic> json) {
    return SubscriptionLimits(
      dailyDiscovers: json['dailyDiscovers'] as int? ?? 50,
      maxQuestions: json['maxQuestions'] as int? ?? 4,
      dailyUndos: json['dailyUndos'] as int? ?? 0,
      monthlyPurpleBonus: json['monthlyPurpleBonus'] as int? ?? 0,
      passportMode: json['passportMode'] as bool? ?? false,
      hasAds: json['hasAds'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        dailyDiscovers,
        maxQuestions,
        dailyUndos,
        monthlyPurpleBonus,
        passportMode,
        hasAds,
      ];
}
