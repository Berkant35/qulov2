import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:uuid/uuid.dart';

typedef RedeemCall = Future<Result<RedeemResult>> Function({
  required String itemId,
  required String idempotencyKey,
  String? sourceItemId,
});

/// Bir itfa sayfasının oturumu (spec §7.4): anahtar sayfa açılınca BİR kez üretilir, tekrar denemede
/// aynı kalır (sunucu aynı anahtarı aynı talep sayar, ikinci düşüm olmaz); istek sürerken ikinci
/// gönderim yapılmaz.
class RedeemSession {
  RedeemSession({required this.itemId, this.sourceItemId, String Function()? newKey})
      : idempotencyKey = (newKey ?? const Uuid().v4)();

  final String itemId;
  final String? sourceItemId;
  final String idempotencyKey;

  bool _inFlight = false;
  bool get inFlight => _inFlight;

  /// İstek sürüyorsa null (gönderilmedi).
  Future<Result<RedeemResult>?> submit(RedeemCall call) async {
    if (_inFlight) return null;
    _inFlight = true;
    try {
      return await call(itemId: itemId, idempotencyKey: idempotencyKey, sourceItemId: sourceItemId);
    } finally {
      _inFlight = false;
    }
  }
}
