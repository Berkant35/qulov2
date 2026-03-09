import 'package:equatable/equatable.dart';

class DailyStats extends Equatable {
  final int dailyDiscoversUsed;
  final int dailyDiscoversLimit;
  final int dailyUndosUsed;
  final int dailyUndosLimit;
  final int questionsCreated;
  final int questionsLimit;
  final int monthlyPurpleBonus;
  final bool passportMode;
  final bool hasAds;

  const DailyStats({
    required this.dailyDiscoversUsed,
    required this.dailyDiscoversLimit,
    required this.dailyUndosUsed,
    required this.dailyUndosLimit,
    required this.questionsCreated,
    required this.questionsLimit,
    required this.monthlyPurpleBonus,
    required this.passportMode,
    required this.hasAds,
  });

  bool get isDiscoverUnlimited => dailyDiscoversLimit == -1;
  bool get isUndoUnlimited => dailyUndosLimit == -1;

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      dailyDiscoversUsed: json['dailyDiscoversUsed'] as int? ?? 0,
      dailyDiscoversLimit: json['dailyDiscoversLimit'] as int? ?? 50,
      dailyUndosUsed: json['dailyUndosUsed'] as int? ?? 0,
      dailyUndosLimit: json['dailyUndosLimit'] as int? ?? 0,
      questionsCreated: json['questionsCreated'] as int? ?? 0,
      questionsLimit: json['questionsLimit'] as int? ?? 4,
      monthlyPurpleBonus: json['monthlyPurpleBonus'] as int? ?? 0,
      passportMode: json['passportMode'] as bool? ?? false,
      hasAds: json['hasAds'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        dailyDiscoversUsed, dailyDiscoversLimit,
        dailyUndosUsed, dailyUndosLimit,
        questionsCreated, questionsLimit,
        monthlyPurpleBonus, passportMode, hasAds,
      ];
}
