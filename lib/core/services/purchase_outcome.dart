import 'package:qulo_v2/core/services/purchase_analytics.dart';

/// Mağaza satın almasının kullanıcıya dönük sonucu.
///
/// Vazgeçme (`purchaseCancelledError`) hata DEĞİLDİR: kullanıcı mağaza
/// penceresini kendisi kapattı, "satın alma başarısız" gösterilmez (2.0.18).
enum PurchaseOutcome {
  success,
  cancelled,
  failed;

  static PurchaseOutcome fromError(Object error) =>
      PurchaseAnalytics.isCancellation(error) ? cancelled : failed;
}
