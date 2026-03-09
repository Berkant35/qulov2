import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/subscription_service.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class SubscriptionRepository implements ISubscriptionRepository {
  final SubscriptionService _service;

  SubscriptionRepository(this._service);

  @override
  Future<Result<SubscriptionInfo>> getStatus() async {
    try {
      final response = await _service.getStatus();
      return Success(response.subscription);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<SubscriptionInfo>> activate(String productId, {String? transactionId}) async {
    try {
      final response = await _service.activate({
        'product_id': productId,
        if (transactionId != null) 'transaction_id': transactionId,
      });
      return Success(response.subscription);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<DailyStats>> getDailyStats() async {
    try {
      final data = await _service.getDailyStats();
      return Success(data);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
