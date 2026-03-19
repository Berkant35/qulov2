import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/referral_service.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class ReferralRepository implements IReferralRepository {
  final ReferralService _service;

  ReferralRepository(this._service);

  @override
  Future<Result<String>> getMyCode() async {
    try {
      final response = await _service.getMyCode();
      final code = response['code'];
      if (code is! String) {
        return const Failure(UnknownFailure(message: 'Missing referral code in response'));
      }
      return Success(code);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }

  @override
  Future<Result<ReferralStats>> getStats() async {
    try {
      final response = await _service.getStats();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<List<ReferralItem>>> getHistory() async {
    try {
      final response = await _service.getHistory();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<ValidateCodeResponse>> validateCode(String code) async {
    try {
      final response = await _service.validateCode({'code': code});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
