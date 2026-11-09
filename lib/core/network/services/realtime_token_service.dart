import 'package:dio/dio.dart';

/// Supabase Realtime kullanıcı token'ı (qulo-server `POST /realtime/token`).
///
/// Kimlik diğer uçlarla aynı (AuthInterceptor Bearer ekler, 401'de yeniler).
class RealtimeTokenService {
  final Dio _dio;

  RealtimeTokenService(this._dio);

  /// Yol [ErrorInterceptor] için de sabit: imzalayıcı yokken dönen 503 raporlanmaz.
  static const path = '/realtime/token';

  /// 503 gövdesindeki kod: sunucuda imzalayıcı yok, istemci anon bağlantıyla sürer.
  static const unavailableCode = 'REALTIME_TOKEN_UNAVAILABLE';

  Future<Object?> issue() async {
    final response = await _dio.post<Object?>(path);
    return response.data;
  }
}
