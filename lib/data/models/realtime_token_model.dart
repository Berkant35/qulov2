import 'package:qulo_v2/data/models/json_read.dart';

/// `POST /realtime/token` yanıtı: Supabase Realtime için kullanıcı başına kısa
/// ömürlü JWT (`role=authenticated`, `sub=users.id`, ömür 10 dk).
///
/// Yalnız Realtime içindir; qulo-server'a `Authorization` olarak gönderilmez.
class RealtimeToken {
  final String token;
  final DateTime expiresAt;

  const RealtimeToken({required this.token, required this.expiresAt});

  /// Eksik ya da bozuk alan varsa `null`: istemci anon bağlantıyla devam eder.
  static RealtimeToken? tryParse(Object? json) {
    final map = jsonMap(json);
    if (map == null) return null;
    final token = jsonText(map['token']);
    final expiresAt = jsonDate(map['expiresAt']);
    if (token == null || expiresAt == null) return null;
    return RealtimeToken(token: token, expiresAt: expiresAt.toUtc());
  }

  /// Şu andan bitişe kalan süre; süresi geçtiyse sıfır ya da negatif.
  Duration remaining(DateTime now) => expiresAt.difference(now.toUtc());
}
