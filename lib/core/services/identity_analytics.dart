import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';

abstract final class IdentityEntryPoint {
  static const banner = 'profile_banner';
  static const editProfile = 'edit_profile';
}

/// Etiket event'leri — yalnız `entry_point`. Değer de grup doluluğu da gönderilmez: GA4 Google
/// Ads'e bağlı, yönelim-var bayrağı hassas kategori vekili olurdu.
abstract final class IdentityAnalytics {
  static void saved({required String entryPoint}) => AnalyticsManager.instance.logEvent(
    AnalyticsEvents.identityLabelsSaved,
    params: {'entry_point': entryPoint},
  );

  static void cleared({required String entryPoint}) => AnalyticsManager.instance.logEvent(
    AnalyticsEvents.identityLabelsCleared,
    params: {'entry_point': entryPoint},
  );
}
