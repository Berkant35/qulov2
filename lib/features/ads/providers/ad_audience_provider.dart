import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/subscription_model.dart';
import 'package:qulo_v2/features/ads/domain/ad_audience.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

/// Abonelik durumunu reklam sınıfına çevirir. Yalnız BAŞARILI ve aboneliksiz
/// yanıt `free` sayılır; hata `unknown` (fail-closed).
///
/// Neden `subscriptionProvider` kullanılmıyor: hata alınca `SubscriptionInfo.free()`
/// döndürüyor — ağ hatalı bir Plus/Premium abonesi "ücretsiz" görünür ve reklam görürdü.
AdAudience audienceFromStatus(Result<SubscriptionInfo> result) => result.when(
      success: (info) => info.isActive ? AdAudience.vip : AdAudience.free,
      failure: (_) => AdAudience.unknown,
    );

/// Reklam açısından kullanıcı sınıfı.
///
/// Uzaktan anahtar kapalıyken ya da oturum yokken HİÇ istek atılmaz (`unknown`).
/// Aboneliği, uygulamanın kendi `subscriptionProvider`'ı aktif gösteriyorsa
/// (satın alma/geri yükleme anlık yansısın) doğrudan `vip`. Satın alma
/// sonrası provider değişince bu provider yeniden hesaplanır.
final adAudienceProvider = FutureProvider<AdAudience>((ref) async {
  if (!ref.watch(adsEnabledProvider)) return AdAudience.unknown;
  final status = ref.watch(authProvider.select((s) => s.status));
  if (status != AuthStatus.authenticated) return AdAudience.unknown;

  final known = ref.watch(subscriptionProvider).valueOrNull;
  if (known != null && known.isActive) return AdAudience.vip;

  try {
    return audienceFromStatus(await ref.read(subscriptionRepositoryProvider).getStatus());
  } catch (_) {
    return AdAudience.unknown;
  }
});
