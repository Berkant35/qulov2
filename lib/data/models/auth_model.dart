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

/// Kayıt yanıtı. 2026-10-04'ten (qulo-server d571dc0) beri sunucu token
/// çiftini de döner: kullanıcı e-postayı doğrulamadan içeri alınır, doğrulama
/// yalnız eşleşmeye ilk yazımda istenir (403 `EMAIL_VERIFICATION_REQUIRED`).
/// Token'lar null ise eski sözleşme: kullanıcı giriş ekranına yönlenir.
@JsonSerializable()
class RegisterResponse extends Equatable {
  @JsonKey(name: 'userId')
  final String userId;
  final String email;
  @JsonKey(name: 'accessToken')
  final String? accessToken;
  @JsonKey(name: 'refreshToken')
  final String? refreshToken;

  const RegisterResponse({
    required this.userId,
    required this.email,
    this.accessToken,
    this.refreshToken,
  });

  /// Doğrudan oturum açmaya yeten token çifti; eski sunucuda null.
  AuthTokens? get tokens => accessToken != null && refreshToken != null
      ? AuthTokens(accessToken: accessToken!, refreshToken: refreshToken!, userId: userId)
      : null;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);

  @override
  List<Object?> get props => [userId, email, accessToken, refreshToken];
}

/// `POST /auth/resend-verification` yanıtı: `sent` = e-posta gitti;
/// `emailVerified` = zaten doğrulanmış (e-posta gönderilmez).
@JsonSerializable()
class ResendVerificationResponse extends Equatable {
  @JsonKey(name: 'emailVerified')
  final bool emailVerified;
  final bool sent;

  const ResendVerificationResponse({this.emailVerified = false, this.sent = false});

  factory ResendVerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$ResendVerificationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ResendVerificationResponseToJson(this);

  @override
  List<Object?> get props => [emailVerified, sent];
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
