import 'package:dio/dio.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/auth_service.dart';
import 'package:qulo_v2/data/models/auth_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class AuthRepository implements IAuthRepository {
  final AuthService _service;

  AuthRepository(this._service);

  @override
  Future<Result<RegisterResponse>> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required int age,
    required String gender,
    String? genderPref,
    String? prefConsentStatus,
    double? lat,
    double? lng,
    String locale = 'tr',
  }) async {
    try {
      final response = await _service.register({
        'email': email,
        'password': password,
        'name': name,
        'surname': surname,
        'age': age,
        'gender': gender,
        if (genderPref != null) 'gender_pref': genderPref,
        if (prefConsentStatus != null)
          'pref_consent': {'status': prefConsentStatus, 'version': PrefConsent.version},
        'locale': locale,
        'tos_accepted': true,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _service.login({
        'email': email,
        'password': password,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<ResendVerificationResponse>> resendVerification() async {
    try {
      return Success(await _service.resendVerification());
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<RefreshResponse>> refresh(String refreshToken) async {
    try {
      final response = await _service.refresh({'refreshToken': refreshToken});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> logout({String? refreshToken}) async {
    try {
      await _service.logout({
        if (refreshToken != null) 'refreshToken': refreshToken,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _service.forgotPassword({'email': email});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _service.resetPassword({'token': token, 'password': password});
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
