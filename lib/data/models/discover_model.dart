import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'discover_model.g.dart';

@JsonSerializable()
class DiscoverResponse extends Equatable {
  final List<ProfileCardModel> cards;
  final int page;
  @JsonKey(name: 'has_more')
  final bool hasMore;

  const DiscoverResponse({
    required this.cards,
    required this.page,
    required this.hasMore,
  });

  factory DiscoverResponse.fromJson(Map<String, dynamic> json) =>
      _$DiscoverResponseFromJson(json);
  Map<String, dynamic> toJson() => _$DiscoverResponseToJson(this);

  @override
  List<Object?> get props => [page, cards.length];
}

@JsonSerializable()
class QuestionInfoModel extends Equatable {
  final int count;
  final List<String> categories;
  @JsonKey(name: 'avg_difficulty')
  final String avgDifficulty;
  final List<String> languages;

  const QuestionInfoModel({
    required this.count,
    this.categories = const [],
    this.avgDifficulty = 'medium',
    this.languages = const [],
  });

  factory QuestionInfoModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionInfoModelFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionInfoModelToJson(this);

  @override
  List<Object?> get props => [count, categories, avgDifficulty, languages];
}

@JsonSerializable()
class ProfileCardModel extends Equatable {
  @JsonKey(name: 'user_id')
  final String userId;
  final String? name;
  final int? age;
  final String? city;
  final String? bio;
  final List<String>? photos;
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  @JsonKey(name: 'question_count')
  final int questionCount;
  @JsonKey(name: 'profile_completion')
  final int profileCompletion;
  @JsonKey(name: 'is_boosted')
  final bool isBoosted;
  @JsonKey(name: 'question_info')
  final QuestionInfoModel? questionInfo;

  const ProfileCardModel({
    required this.userId,
    this.name,
    this.age,
    this.city,
    this.bio,
    this.photos,
    required this.distanceKm,
    required this.questionCount,
    this.profileCompletion = 0,
    this.isBoosted = false,
    this.questionInfo,
  });

  factory ProfileCardModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileCardModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileCardModelToJson(this);

  @override
  List<Object?> get props => [userId];
}

@JsonSerializable()
class SwipeResponse extends Equatable {
  final bool matched;

  const SwipeResponse({required this.matched});

  factory SwipeResponse.fromJson(Map<String, dynamic> json) =>
      _$SwipeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SwipeResponseToJson(this);

  @override
  List<Object?> get props => [matched];
}
