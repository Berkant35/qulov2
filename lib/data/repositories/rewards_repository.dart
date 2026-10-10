import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/rewards_service.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class RewardsRepository implements IRewardsRepository {
  RewardsRepository(this._service);

  final RewardsService _service;

  @override
  Future<Result<MarketView>> getMarket({String? country}) =>
      _guard(() async => MarketView.fromJson(await _service.getMarket(country: country)));

  @override
  Future<Result<RedeemResult>> redeem({
    required String itemId,
    required String idempotencyKey,
    String? sourceItemId,
  }) =>
      _guard(() async => RedeemResult.fromJson(await _service.redeem(
            {
              'item_id': itemId,
              'idempotency_key': idempotencyKey,
              if (sourceItemId != null) 'source_item_id': sourceItemId,
            },
            idempotencyKey: idempotencyKey,
          )));

  @override
  Future<Result<RedemptionPage>> getRedemptions({int page = 1, int limit = 20}) =>
      _guard(() async => RedemptionPage.fromJson(await _service.getRedemptions(page: page, limit: limit)));

  @override
  Future<Result<void>> sendEvents(List<SectionEvent> events) =>
      _guard(() => _service.sendEvents(events.map((e) => e.toJson()).toList()));

  /// Ağ hatası → `toAppFailure`; bozuk yanıt (FormatException/TypeError) → `UnknownFailure` (çökme yok).
  static Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    } catch (e) {
      return Failure(UnknownFailure(error: e));
    }
  }
}
