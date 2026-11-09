import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/city_service.dart';
import 'package:qulo_v2/data/models/city_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

class CityRepository implements ICityRepository {
  final CityService _service;

  CityRepository(this._service);

  /// Sunucu `q` için 50 karakter sınırı koyar; fazlası 400 olmasın diye kırpılır.
  static const maxQueryLength = 50;
  static const cityNotFoundCode = 'CITY_NOT_FOUND';

  @override
  Future<Result<CityListResponse>> search({String? country, String query = '', int limit = 100}) async {
    try {
      final q = query.trim();
      final data = await _service.search(
        country: country,
        query: q.length > maxQueryLength ? q.substring(0, maxQueryLength) : q,
        limit: limit,
      );
      return Success(CityListResponse.fromJson(data));
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  @override
  Future<Result<void>> setCity(String cityId) async {
    try {
      await _service.setCity(cityId);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
