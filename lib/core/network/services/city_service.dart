import 'package:dio/dio.dart';

/// Konumsuz yedek yol: statik şehir listesi + seçimi kaydetme (sunucu 2.0.18).
class CityService {
  final Dio _dio;

  CityService(this._dio);

  /// Kimlik gerekmez; aksan duyarsız arama, takma adlar da bulunur.
  Future<Object?> search({String? country, String? query, int? limit}) async {
    final response = await _dio.get<Object?>(
      '/app/cities',
      queryParameters: {
        if (country != null) 'country': country,
        if (query != null && query.isNotEmpty) 'q': query,
        if (limit != null) 'limit': limit,
      },
    );
    return response.data;
  }

  /// Sunucu şehir merkezini `users.lat/lng`'ye yazar (`location_source = city`).
  Future<void> setCity(String cityId) async {
    await _dio.patch<Object?>('/users/me/location/city', data: {'city_id': cityId});
  }
}
