import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';

part 'public_profile_model.g.dart';

@JsonSerializable()
class PublicProfileModel extends Equatable {
  @JsonKey(name: 'user_id')
  final String userId;
  final String? name;
  final int? age;
  final String? bio;
  final String? city;
  final String? country;
  final List<String> photos;
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  @JsonKey(name: 'relationship_goal')
  final String? relationshipGoal;
  @JsonKey(name: 'is_online')
  final bool? isOnline;
  @JsonKey(name: 'last_seen')
  final String? lastSeen;
  @JsonKey(name: 'profile_completion')
  final int profileCompletion;
  @JsonKey(name: 'is_boosted')
  final bool isBoosted;
  final UserDetailsModel? details;
  @JsonKey(name: 'question_info')
  final QuestionInfoModel? questionInfo;

  const PublicProfileModel({
    required this.userId,
    this.name,
    this.age,
    this.bio,
    this.city,
    this.country,
    this.photos = const [],
    this.distanceKm = 0,
    this.relationshipGoal,
    this.isOnline,
    this.lastSeen,
    this.profileCompletion = 0,
    this.isBoosted = false,
    this.details,
    this.questionInfo,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$PublicProfileModelToJson(this);

  @override
  List<Object?> get props => [userId];
}
