import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';

import 'package:qulo_v2/data/models/diamond_model.dart';
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
  @JsonKey(name: 'gender_pref_set_at')
  final DateTime? genderPrefSetAt;
  /// Eşleşme tercihi rızası: `GRANTED`, `DECLINED` ya da null (sorulmadı).
  @JsonKey(name: 'pref_consent_status')
  final String? prefConsentStatus;
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
  @JsonKey(name: 'rainbow_diamonds', defaultValue: 0)
  final int rainbowDiamonds;

  /// Sunucunun tek kaynaklı kararı (`rainbowAccessService`): Rainbow bakiyesi, güç alımında
  /// Rainbow ve market YALNIZ bu true iken görünür. İstemci ülke/platformdan kendisi hesaplamaz.
  @JsonKey(name: 'rainbow_enabled', defaultValue: false)
  final bool rainbowEnabled;

  /// Kullanıcının en az bir hediye kartı talebi var. "Hediye kartlarım" girişi Rainbow
  /// kapalıyken de görünür (market ülkesinden dönen turist teslim edilen koduna ulaşabilsin).
  @JsonKey(name: 'has_reward_redemptions', defaultValue: false)
  final bool hasRewardRedemptions;
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

  /// Sorularin dil dagilimi, ornegin `{ 'tr': 3, 'en': 1 }`.
  ///
  /// BILGI, teshis DEGIL. Bundan "kimseye gorunmuyorsun" cikarilamaz: sunucu
  /// dil basina degil, izleyicinin okudugu dillerdeki sorularin TOPLAMINI
  /// sayiyor (matching.service.ts:242). Izleyici tr+en okuyorsa {tr:1, en:1}
  /// olan profil filtreyi gecer.
  ///
  /// `null` = sunucu bu bilgiyi vermedi (eski surum ya da sorgu hatasi) —
  /// o durumda gosterilecek bir sey yok, bos harita ile karistirma.
  @JsonKey(name: 'question_locales')
  final Map<String, int>? questionLocales;
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
  @JsonKey(name: 'acquisition_answered', defaultValue: false)
  final bool acquisitionAnswered;
  @JsonKey(name: 'interests', defaultValue: <String>[])
  final List<String> interests;
  @JsonKey(name: 'email_notifications_enabled', defaultValue: true)
  final bool emailNotificationsEnabled;
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
    this.genderPrefSetAt,
    this.prefConsentStatus,
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
    this.rainbowDiamonds = 0,
    this.rainbowEnabled = false,
    this.hasRewardRedemptions = false,
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
    this.questionLocales,
    this.relationshipGoal,
    this.preferredLanguages = const [],
    this.completionRewardsClaimed = const {},
    this.strictLanguageMode = false,
    this.referralCode,
    this.acquisitionAnswered = false,
    this.interests = const [],
    this.emailNotificationsEnabled = true,
    this.details,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Mor bakiyesi degistirilmis kopya — guc harcamasi yerel dusulurken kullanilir.
  ///
  /// 43 alanlik elle `copyWith` yerine JSON round-trip: `toJson`/`fromJson` simetrik
  /// kaldigi surece yeni alanlar otomatik korunur; ic ice modeller (`details`)
  /// `jsonEncode` ile map'e iner. Nadir cagrilir (guc basina bir kez).
  UserModel withPurpleDiamonds(int purple) {
    final json = jsonDecode(jsonEncode(this)) as Map<String, dynamic>;
    return UserModel.fromJson(json..['purple_diamonds'] = purple);
  }

  /// Üç bakiyesi sunucunun bildirdiği değerlerle değiştirilmiş kopya (güç alımı `new_balance`).
  /// `withPurpleDiamonds` ile aynı JSON round-trip deseni: yeni alanlar otomatik korunur.
  UserModel withBalances(DiamondBalance balance) {
    final json = jsonDecode(jsonEncode(this)) as Map<String, dynamic>;
    return UserModel.fromJson(json
      ..['green_diamonds'] = balance.green
      ..['purple_diamonds'] = balance.purple
      ..['rainbow_diamonds'] = balance.rainbow);
  }

  /// Esikler `AppConstants`'tan geliyor: ayni sunucu kurali
  /// (`matching.service.ts` adim 5.5) `missingVisibilityGates` icinde de
  /// ifade ediliyor ve iki yerde ayri sabit tutmak, sunucu esigi degistiginde
  /// birinin sessizce bayatlamasi demekti.
  ///
  /// Uc parca ayri getter: kurulum ekraninin kartlari da bunlara bakar, router
  /// kapisi (`setupComplete`) ile ekran ayni esigi kullanir.
  bool get hasSetupPhoto => (photos?.length ?? 0) >= AppConstants.minPhotos;
  bool get hasSetupQuestions => questionCount >= AppConstants.minQuestions;
  bool get prefConsentDeclined => prefConsentStatus == PrefConsent.declined;

  /// Tercih seçilmiş ya da rıza reddedilmiş ("Herkes" modu) — ikisinde de Discover açılır.
  bool get hasGenderPref => genderPrefSetAt != null || prefConsentDeclined;

  /// Rızasız alınmış tercih (2.0.14 ve öncesi, ya da destekle değişmiş tercih): bir kerelik sor.
  bool get needsPrefConsent => genderPrefSetAt != null && prefConsentStatus == null;

  bool get setupComplete => hasSetupPhoto && hasSetupQuestions && hasGenderPref;

  @override
  List<Object?> get props => [
    id, email, name, surname, bio, age, gender, genderPref, genderPrefSetAt, prefConsentStatus,
    matchRadiusKm, agePrefMin, agePrefMax, city, country, locale,
    lat, lng, photos, profileCompletion, greenDiamonds, purpleDiamonds,
    rainbowDiamonds, rainbowEnabled, hasRewardRedemptions,
    isOnline, lastSeenAt, emailVerified, passportCity, boostUntil,
    likeReceivedCount, timesShownCount, badgeRewardsClaimed, questionCount, questionLocales,
    relationshipGoal, preferredLanguages, completionRewardsClaimed, strictLanguageMode, referralCode,
    acquisitionAnswered,
    interests,
    emailNotificationsEnabled,
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
      distanceKm: null,
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
