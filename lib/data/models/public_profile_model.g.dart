// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicProfileModel _$PublicProfileModelFromJson(Map<String, dynamic> json) =>
    PublicProfileModel(
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      age: (json['age'] as num?)?.toInt(),
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      relationshipGoal: json['relationship_goal'] as String?,
      isOnline: json['is_online'] as bool?,
      lastSeen: json['last_seen'] as String?,
      profileCompletion: (json['profile_completion'] as num?)?.toInt() ?? 0,
      isBoosted: json['is_boosted'] as bool? ?? false,
      details: json['details'] == null
          ? null
          : UserDetailsModel.fromJson(json['details'] as Map<String, dynamic>),
      questionInfo: json['question_info'] == null
          ? null
          : QuestionInfoModel.fromJson(
              json['question_info'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PublicProfileModelToJson(PublicProfileModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'age': instance.age,
      'bio': instance.bio,
      'city': instance.city,
      'country': instance.country,
      'photos': instance.photos,
      'distance_km': instance.distanceKm,
      'relationship_goal': instance.relationshipGoal,
      'is_online': instance.isOnline,
      'last_seen': instance.lastSeen,
      'profile_completion': instance.profileCompletion,
      'is_boosted': instance.isBoosted,
      'details': instance.details,
      'question_info': instance.questionInfo,
    };
