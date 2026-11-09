import 'package:dio/dio.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/network/services/realtime_token_service.dart';
import 'package:qulo_v2/data/models/realtime_token_model.dart';
import 'package:qulo_v2/data/repositories/interfaces.dart';

/// Realtime kullanıcı token'ı. Hata kodu sözleşmesi (`tasks/surum-2.0.18-sozlesmeler.md`):
/// 503 `REALTIME_TOKEN_UNAVAILABLE` = sunucuda imzalayıcı yok, 429 `RATE_LIMITED`.
/// İkisinde de çağıran anon bağlantıyla devam eder; burada yalnız eşleme yapılır.
class RealtimeTokenRepository implements IRealtimeTokenRepository {
  final RealtimeTokenService _service;

  RealtimeTokenRepository(this._service);

  static const malformedCode = 'REALTIME_TOKEN_MALFORMED';

  @override
  Future<Result<RealtimeToken>> issue() async {
    try {
      final token = RealtimeToken.tryParse(await _service.issue());
      if (token == null) return const Failure(ServerFailure(code: malformedCode));
      return Success(token);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
