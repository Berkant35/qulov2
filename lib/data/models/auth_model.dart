import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class AuthTokens extends Equatable {
  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;
  @JsonKey(name: 'userId')
  final String userId;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);

  @override
  List<Object?> get props => [accessToken, refreshToken, userId];
}

@JsonSerializable()
class RegisterResponse extends Equatable {
  @JsonKey(name: 'userId')
  final String userId;
  final String email;

  const RegisterResponse({required this.userId, required this.email});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);

  @override
  List<Object?> get props => [userId, email];
}

@JsonSerializable()
class RefreshResponse extends Equatable {
  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;

  const RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshResponseToJson(this);

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

@JsonSerializable()
class SocialLoginResponse extends Equatable {
  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;
  @JsonKey(name: 'userId')
  final String userId;
  @JsonKey(name: 'profileIncomplete')
  final bool profileIncomplete;

  const SocialLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.profileIncomplete,
  });

  factory SocialLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SocialLoginResponseToJson(this);

  @override
  List<Object?> get props => [accessToken, refreshToken, userId, profileIncomplete];
}
