import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'match_model.g.dart';

@JsonSerializable()
class MatchModel extends Equatable {
  @JsonKey(name: 'match_id')
  final String matchId;
  @JsonKey(name: 'matched_at')
  final String matchedAt;
  final MatchUserModel? user;

  const MatchModel({
    required this.matchId,
    required this.matchedAt,
    this.user,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchModelToJson(this);

  @override
  List<Object?> get props => [matchId];
}

@JsonSerializable()
class MatchUserModel extends Equatable {
  @JsonKey(name: 'user_id')
  final String userId;
  final String? name;
  final int? age;
  final String? city;
  final List<String>? photos;
  final String? bio;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'last_seen')
  final String? lastSeen;

  const MatchUserModel({
    required this.userId,
    this.name,
    this.age,
    this.city,
    this.photos,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
  });

  factory MatchUserModel.fromJson(Map<String, dynamic> json) =>
      _$MatchUserModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchUserModelToJson(this);

  @override
  List<Object?> get props => [userId];
}
