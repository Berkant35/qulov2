import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/diamond_service.dart';
import 'package:qulo_v2/data/models/diamond_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class DiamondRepository implements IDiamondRepository {
  final DiamondService _service;

  DiamondRepository(this._service);

  @override
  Future<Result<DiamondBalance>> getBalance() async {
    try {
      final response = await _service.getBalance();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<DiamondHistoryResponse>> getHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await _service.getHistory(page, limit);
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> purchase(String iapProductId, {String? transactionId}) async {
    try {
      await _service.purchase({
        'product_id': iapProductId,
        'platform': 'ios',
        if (transactionId != null) 'transaction_id': transactionId,
      });
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
