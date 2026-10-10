import 'package:dio/dio.dart';

/// Rainbow market uçları (`/api/v1/rewards/*`). `Accept-Language` + `x-app-platform` interceptor'dan gelir.
class RewardsService {
  RewardsService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMarket({String? country}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rewards/market',
      queryParameters: {if (country != null) 'country': country},
    );
    return response.data ?? const {};
  }

  /// Başlıktaki anahtar gövdedekiyle aynı: interceptor `??=` ile üzerine yazmaz, tekrar denemede aynı kalır.
  Future<Map<String, dynamic>> redeem(Map<String, dynamic> body, {required String idempotencyKey}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/rewards/redeem',
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> getRedemptions({required int page, required int limit}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/rewards/redemptions',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data ?? const {};
  }

  Future<void> sendEvents(List<Map<String, dynamic>> events) async {
    await _dio.post<void>('/rewards/events', data: {'events': events});
  }
}
