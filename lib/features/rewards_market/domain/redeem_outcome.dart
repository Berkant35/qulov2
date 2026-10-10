import 'package:qulo_v2/features/rewards_market/domain/redeem_error.dart';

/// İtfa gönderiminin ekrana söylediği (spec §7.4). Yan etkiler (bakiye, market, kullanıcı yenileme,
/// GA4) `RedeemFlow` içinde zaten uygulanmıştır; ekran yalnız sayfayı/snackbar'ı yönetir.
sealed class RedeemOutcome {
  const RedeemOutcome();
}

/// İstek zaten sürüyordu: hiçbir şey gönderilmedi, ekran bir şey yapmaz.
final class RedeemIgnored extends RedeemOutcome {
  const RedeemIgnored();
}

/// Sayfa kapanır + snackbar. [error] null = başarı; [withView] = "Görüntüle" (Hediye kartlarım).
final class RedeemClose extends RedeemOutcome {
  const RedeemClose({this.error, this.withView = false});

  final RedeemError? error;
  final bool withView;
}

/// Hata sayfada satır içi gösterilir (tekrar denenebilir: aynı anahtar).
final class RedeemInline extends RedeemOutcome {
  const RedeemInline(this.error);

  final RedeemError error;
}
