// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String?,
  surname: json['surname'] as String?,
  bio: json['bio'] as String?,
  age: (json['age'] as num?)?.toInt(),
  gender: json['gender'] as String?,
  genderPref: json['gender_pref'] as String?,
  matchRadiusKm: (json['match_radius_km'] as num?)?.toInt() ?? 50,
  agePrefMin: (json['age_pref_min'] as num?)?.toInt(),
  agePrefMax: (json['age_pref_max'] as num?)?.toInt(),
  city: json['city'] as String?,
  country: json['country'] as String?,
  locale: json['locale'] as String?,
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
  profileCompletion: (json['profile_completion'] as num?)?.toInt() ?? 0,
  greenDiamonds: (json['green_diamonds'] as num?)?.toInt() ?? 0,
  purpleDiamonds: (json['purple_diamonds'] as num?)?.toInt() ?? 0,
  isOnline: json['is_online'] as bool? ?? false,
  lastSeenAt: json['last_seen_at'] as String?,
  pushToken: json['push_token'] as String?,
  emailVerified: json['email_verified'] as bool? ?? false,
  passportCity: json['passport_city'] as String?,
  passportLat: (json['passport_lat'] as num?)?.toDouble(),
  passportLng: (json['passport_lng'] as num?)?.toDouble(),
  boostUntil: json['boost_until'] as String?,
  likeReceivedCount: (json['like_received_count'] as num?)?.toInt() ?? 0,
  timesShownCount: (json['times_shown_count'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] as String?,
  badgeRewardsClaimed:
      (json['badge_rewards_claimed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
  relationshipGoal: json['relationship_goal'] as String?,
  preferredLanguages:
      (json['preferred_languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  completionRewardsClaimed:
      json['completion_rewards_claimed'] as Map<String, dynamic>? ?? {},
  strictLanguageMode: json['strict_language_mode'] as bool? ?? false,
  referralCode: json['referral_code'] as String?,
  details: json['details'] == null
      ? null
      : UserDetailsModel.fromJson(json['details'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'surname': instance.surname,
  'bio': instance.bio,
  'age': instance.age,
  'gender': instance.gender,
  'gender_pref': instance.genderPref,
  'match_radius_km': instance.matchRadiusKm,
  'age_pref_min': instance.agePrefMin,
  'age_pref_max': instance.agePrefMax,
  'city': instance.city,
  'country': instance.country,
  'locale': instance.locale,
  'lat': instance.lat,
  'lng': instance.lng,
  'photos': instance.photos,
  'profile_completion': instance.profileCompletion,
  'green_diamonds': instance.greenDiamonds,
  'purple_diamonds': instance.purpleDiamonds,
  'is_online': instance.isOnline,
  'last_seen_at': instance.lastSeenAt,
  'push_token': instance.pushToken,
  'email_verified': instance.emailVerified,
  'passport_city': instance.passportCity,
  'passport_lat': instance.passportLat,
  'passport_lng': instance.passportLng,
  'boost_until': instance.boostUntil,
  'like_received_count': instance.likeReceivedCount,
  'times_shown_count': instance.timesShownCount,
  'created_at': instance.createdAt,
  'badge_rewards_claimed': instance.badgeRewardsClaimed,
  'question_count': instance.questionCount,
  'relationship_goal': instance.relationshipGoal,
  'preferred_languages': instance.preferredLanguages,
  'completion_rewards_claimed': instance.completionRewardsClaimed,
  'strict_language_mode': instance.strictLanguageMode,
  'referral_code': instance.referralCode,
  'details': instance.details,
};
