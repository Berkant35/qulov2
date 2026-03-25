import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/data/models/user_details_model.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? surname;
  final String? bio;
  final int? age;
  final String? gender;
  @JsonKey(name: 'gender_pref')
  final String? genderPref;
  @JsonKey(name: 'match_radius_km', defaultValue: 50)
  final int matchRadiusKm;
  @JsonKey(name: 'age_pref_min')
  final int? agePrefMin;
  @JsonKey(name: 'age_pref_max')
  final int? agePrefMax;
  final String? city;
  final String? country;
  final String? locale;
  final double? lat;
  final double? lng;
  final List<String>? photos;
  @JsonKey(name: 'profile_completion')
  final int profileCompletion;
  @JsonKey(name: 'green_diamonds')
  final int greenDiamonds;
  @JsonKey(name: 'purple_diamonds')
  final int purpleDiamonds;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'last_seen_at')
  final String? lastSeenAt;
  @JsonKey(name: 'push_token')
  final String? pushToken;
  @JsonKey(name: 'email_verified')
  final bool emailVerified;
  @JsonKey(name: 'passport_city')
  final String? passportCity;
  @JsonKey(name: 'passport_lat')
  final double? passportLat;
  @JsonKey(name: 'passport_lng')
  final double? passportLng;
  @JsonKey(name: 'boost_until')
  final String? boostUntil;
  @JsonKey(name: 'like_received_count')
  final int likeReceivedCount;
  @JsonKey(name: 'times_shown_count')
  final int timesShownCount;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'badge_rewards_claimed')
  final List<String> badgeRewardsClaimed;
  @JsonKey(name: 'question_count', defaultValue: 0)
  final int questionCount;
  @JsonKey(name: 'relationship_goal')
  final String? relationshipGoal;
  @JsonKey(name: 'preferred_languages', defaultValue: [])
  final List<String> preferredLanguages;
  @JsonKey(name: 'completion_rewards_claimed', defaultValue: {})
  final Map<String, dynamic> completionRewardsClaimed;
  @JsonKey(name: 'strict_language_mode', defaultValue: false)
  final bool strictLanguageMode;
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  final UserDetailsModel? details;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.surname,
    this.bio,
    this.age,
    this.gender,
    this.genderPref,
    this.matchRadiusKm = 50,
    this.agePrefMin,
    this.agePrefMax,
    this.city,
    this.country,
    this.locale,
    this.lat,
    this.lng,
    this.photos,
    this.profileCompletion = 0,
    this.greenDiamonds = 0,
    this.purpleDiamonds = 0,
    this.isOnline = false,
    this.lastSeenAt,
    this.pushToken,
    this.emailVerified = false,
    this.passportCity,
    this.passportLat,
    this.passportLng,
    this.boostUntil,
    this.likeReceivedCount = 0,
    this.timesShownCount = 0,
    this.createdAt,
    this.badgeRewardsClaimed = const [],
    this.questionCount = 0,
    this.relationshipGoal,
    this.preferredLanguages = const [],
    this.completionRewardsClaimed = const {},
    this.strictLanguageMode = false,
    this.referralCode,
    this.details,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  List<Object?> get props => [
    id, email, name, surname, bio, age, gender, genderPref,
    matchRadiusKm, agePrefMin, agePrefMax, city, country, locale,
    lat, lng, photos, profileCompletion, greenDiamonds, purpleDiamonds,
    isOnline, lastSeenAt, emailVerified, passportCity, boostUntil,
    likeReceivedCount, timesShownCount, badgeRewardsClaimed, questionCount,
    relationshipGoal, preferredLanguages, completionRewardsClaimed, strictLanguageMode, referralCode,
  ];
}

extension UserModelToPublicProfile on UserModel {
  PublicProfileModel toPublicProfile() {
    return PublicProfileModel(
      userId: id,
      name: name,
      age: age,
      bio: bio,
      city: city,
      country: country,
      photos: photos ?? [],
      distanceKm: 0,
      relationshipGoal: relationshipGoal,
      isOnline: false,
      lastSeen: null,
      profileCompletion: profileCompletion,
      isBoosted: boostUntil != null &&
          DateTime.tryParse(boostUntil!)?.isAfter(DateTime.now().toUtc()) ==
              true,
      details: details,
      questionInfo: QuestionInfoModel(
        count: questionCount,
      ),
    );
  }
}
