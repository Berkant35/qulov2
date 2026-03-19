import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/exchange_service.dart';
import 'package:qulo_v2/data/models/exchange_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class ExchangeRepository implements IExchangeRepository {
  final ExchangeService _service;

  ExchangeRepository(this._service);

  @override
  Future<Result<ConvertResponse>> convert(int greenAmount) async {
    try {
      final response = await _service.convert({'green_amount': greenAmount});
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<BuyPowerResponse>> buyPower(
    String powerName,
    String diamondType,
    int quantity,
  ) async {
    try {
      final response = await _service.buyPower({
        'power_name': powerName,
        'diamond_type': diamondType,
        'quantity': quantity,
      });
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<InventoryResponse>> getInventory() async {
    try {
      final response = await _service.getInventory();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<RatesResponse>> getRates() async {
    try {
      final response = await _service.getRates();
      return Success(response);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
